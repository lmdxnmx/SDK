//
//  Elta.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 04.07.2023.
//

import Foundation
import CoreBluetooth

public class EltaGlucometr:
    ConnectClass,
    DeviceScaningDelegate,
    DeviceConnectionDelegate,
    ServicesDiscoveryDelegate,
    ReadWirteCharteristicDelegate{
    
    internal var _identifer: UUID?

    public var peripherals: [DisplayPeripheral] = []
    
    static var itter:Int = 0
    
    internal var rxtxService: CBService?
    
    internal var rxCharacteistic: CBCharacteristic?
    
    internal var txCharacteistic: CBCharacteristic?
    
    internal var internetManager: InternetManager = InternetManager.getManager()
    
    internal var measurements: Collector?
    
    public static var lastDateMeasurements: Date? = nil
    
    internal static let FormatPlatformTime: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.formatOptions = [.withInternetDateTime]
        return dateFormatter
    }()
    
    ///Объект для форматирования времени при записи данны
    internal static let FormatDeviceTime: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyMMddHHmmss"
        df.timeZone = TimeZone.current
        return df
    }()
    
    internal let manager: BLEManager = {
        return BLEManager.getSharedBLEManager()
    }()
    
    internal func getLastTime(serial: String){
        internetManager.getTime(serial: serial)
    }
    
    override public func connect(device: CBPeripheral) {
        EltaGlucometr.activeExecute = true
        manager.connectionDelegate = self
        _identifer = device.identifier
        manager.connectPeripheralDevice(peripheral: device, options: nil)
        sleep(25)
        manager.disconnectPeripheralDevice(peripheral: device)
        EltaGlucometr.activeExecute = false
    }
    
    override public func search(timeout: UInt32) {
        manager.scaningDelegate = self
        manager.scanAllDevices()
        sleep(timeout)
        manager.stopScan()
        callback?.searchedDevices(peripherals: peripherals)
    }
    
    //DeviceScaningDelegate
    internal func scanningStatus(status: Int) {
        print(status)
    }
    
    internal func bleManagerDiscover(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if(peripheral.name != nil){
            for (index, foundPeripheral) in peripherals.enumerated() {
                if foundPeripheral.peripheral?.identifier == peripheral.identifier {
                    peripherals[index].lastRSSI = RSSI
                    peripherals[index].peripheral = peripheral
                    return
                }
            }
            let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as? Bool
            let localName = peripheral.name!
            let displayPeripheral: DisplayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, isConnectable: isConnectable!, localName: localName)
            callback?.findDevice(peripheral: displayPeripheral);
            peripherals.append(displayPeripheral)
        }
    }
    
    //DeviceConnectingDelegate
    internal func bleManagerConnectionFail(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        callback?.onExpection(mac: _identifer!, ex: error!)
    }
    
    // This method will be triggered once device will be connected.
    internal func bleManagerDidConnect(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        manager.discoveryDelegate = self
        manager.readWriteCharDelegate = self
        callback?.onStatusDevice(mac: _identifer!, status: BluetoothStatus.ConnectStart)
        peripheral.discoverServices(nil)
        EltaGlucometr.itter = 0
        self.measurements = Collector()
    }
    
    // This method will be triggered once device will be disconnected.
    internal func bleManagerDisConect(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        callback?.onStatusDevice(mac: _identifer!, status: BluetoothStatus.ConnectDisconnect)
        if(self.measurements == nil) { return; }
        let ret = self.measurements?.returnData()
        callback?.onDisconnect(mac: peripheral.identifier, data: ret!)
        DispatchQueue.global().async {
            sleep(5)
            let serial = self.measurements!.returnCharateristic(atribute: Atributes.SerialNumber) as! String
            let model = self.measurements!.returnCharateristic(atribute: Atributes.ModelNumber) as! String
            var measurements: Array<Measurements>
            if(EltaGlucometr.lastDateMeasurements != nil){
                measurements = (self.measurements?.returnMeasurements(offsetTime: EltaGlucometr.lastDateMeasurements!) as? Array<Measurements>)!
            } else {
                measurements = (self.measurements?.returnMeasurements() as? Array<Measurements>)!
            }
            for measurement in measurements {
                let time = measurement.get(atr: Atributes.TimeStamp) as! Date
                let value = measurement.get(atr: Atributes.Glucose) as! Double
                let postData = FhirTemplate.Glucometer(serial: serial, model: model, effectiveDateTime: time, value: value)
                self.internetManager.postResource(identifier: peripheral.identifier, data: postData!)
            }
            if(measurements.count == 0){
                self.callback?.onSendData(mac: peripheral.identifier, status: PlatformStatus.NoDataSend)
            }
        }
    }
    
    //ReadWirteCharteristicDelegate
    internal func bleManagerDidUpdateValueForChar(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if let resultStr = String(data: characteristic.value!, encoding: .utf8) {
            if(resultStr.contains("enter pincode first")){
                callback?.onStatusDevice(mac: peripheral.identifier, status: BluetoothStatus.NotCorrectPin)
                manager.disconnectPeripheralDevice(peripheral: peripheral)
            }
            if(resultStr.starts(with: "ser.")){
                let serial = resultStr.replacingOccurrences(of: "ser.", with: "")
                getLastTime(serial: serial)
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.SerialNumber, value: serial)
                self.measurements!.addInfo(atr: Atributes.SerialNumber, value: serial)
            }
            if(resultStr.starts(with: "b")){
                let data = resultStr.replacingOccurrences(of: "b", with: "").replacingOccurrences(of: "t", with: "").split(separator: ".")
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.BatteryLevel, value: data[0])
                self.measurements!.addInfo(atr: Atributes.BatteryLevel, value: data[0])
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.Temperature, value: data[1])
                self.measurements!.addInfo(atr: Atributes.Temperature, value: data[1])
            }
            if(resultStr.starts(with: "rd")){
                let measurement = resultStr.replacingOccurrences(of: "rd", with: "")
                if measurement.replacingOccurrences(of: "0", with: "").count == 0 {
                    manager.disconnectPeripheralDevice(peripheral: peripheral)
                    EltaGlucometr.activeExecute = false
                    return
                }
                let dateStr: String = String(measurement.prefix(12))
                let start = measurement.index(measurement.startIndex, offsetBy: 12)
                let end = measurement.index(measurement.startIndex, offsetBy: 15)
                let temperatureStr: String = String(measurement[start...end])
                let valueStr: String = String(measurement.suffix(from: measurement.index(measurement.startIndex, offsetBy: 15)))
                
                var m = Measurements()
                let timeStamp = EltaGlucometr.FormatDeviceTime.date(from: dateStr)!
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.TimeStamp, value: timeStamp)
                m.add(atr: Atributes.TimeStamp, value: timeStamp)
                
                let temperature: Double = Double(temperatureStr)! / 10
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.Temperature, value: temperature)
                m.add(atr: Atributes.Temperature, value: temperature)
                
                let value: Double = Double(valueStr)! / 10
                callback?.onExploreDevice(mac: peripheral.identifier, atr: Atributes.Glucose, value: value)
                m.add(atr: Atributes.Glucose, value: value)
                
                self.measurements!.addMeasurements(Object: m)
                EltaGlucometr.itter += 1
                getRDS(device: peripheral)
            }
        }
    }
    
    internal func bleManagerDidWriteValueForChar(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){ }
    
    internal func bleManagerDidUpdateValueForDesc(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?){}
    
    internal func bleManagerDidWriteValueForDesc(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?){}

    //Обработчик:
    internal func bleManagerDidUpdateNotificationState(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){ }
    
    //ServicesDiscoveryDelegate
    internal func bleManagerDiscoverService (_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        } else {
            print("No services found")
        }
    }
    internal func bleManagerDiscoverCharacteristics (_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        rxtxService = service
        rxCharacteistic = rxtxService!.characteristics![0]
        txCharacteistic = rxtxService!.characteristics![1]
        peripheral.setNotifyValue(true, for: txCharacteistic!)
        setPin(device: peripheral)
        getSerial(device: peripheral)
        getDisplay(device: peripheral)
        setTime(device: peripheral)
        getBattery(device: peripheral)
        getRDS(device: peripheral)
    }
    internal func bleManagerDiscoverDescriptors(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        print("bleManagerDiscoverDescriptors")
    }
    
    internal func setPin(device: CBPeripheral){
        let response: Data = ("pin."+cred!).data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    internal func getRDS(device: CBPeripheral){
        let response: Data = String(format: "rd.%03dd", EltaGlucometr.itter).data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    internal func getDisplay(device: CBPeripheral){
        let modelNumber = "SatelliteOnline"
        self.measurements!.addInfo(atr: Atributes.ModelNumber, value: modelNumber)
        callback?.onExploreDevice(mac: device.identifier, atr: Atributes.ModelNumber, value: modelNumber)
    }
    
    internal func getSerial(device: CBPeripheral){
        let response: Data = String("serial").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    internal func setTime(device: CBPeripheral){
        let timeNow = Date()
        let time = EltaGlucometr.FormatDeviceTime.string(from: timeNow)
        print("Settime: " + time)
        let response: Data = String("settime." + time).data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    internal func getBattery(device: CBPeripheral){
        let response: Data = String("bat").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
}

