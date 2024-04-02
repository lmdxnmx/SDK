//
//  Elta.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 04.07.2023.
//

import Foundation
import CoreBluetooth
import CommonCrypto

public class DoctisFetal:
    ConnectClass,
    DeviceScaningDelegate,
    DeviceConnectionDelegate,
    ServicesDiscoveryDelegate,
    ReadWirteCharteristicDelegate,
    BLEIndicateCallback{
    
    
    internal var _identifer: UUID?
    internal var _mac:String?
    var peripheral: CBPeripheral?
    var serial:String = "";
    static var mail:String = "";
    public var peripherals: [DisplayPeripheral] = []
    var decoder = LMTPDecoder()
    static var itter:Int = 0
    
    internal var rxtxService: CBService?
    
    internal var rxCharacteistic: CBCharacteristic?
    
    internal var txCharacteistic: CBCharacteristic?
    
    internal var internetManager: InternetManager = InternetManager.getManager()
    
    internal var measurements: Collector?
    let bloodPressureMeasurementUUID = CBUUID(string: "0000FFF1-0000-1000-8000-00805F9B34FB")
    let heartPressureMeasurementUUID = CBUUID(string: "0000FFF0-0000-1000-8000-00805F9B34FB")
    var disconnectTimer: Timer? = nil
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
        DoctisFetal.activeExecute = true
        manager.connectionDelegate = self
        _identifer = device.identifier
        manager.connectPeripheralDevice(peripheral: device, options: nil)
        DoctisFetal.activeExecute = false
    }

    
    override public func search(timeout: UInt32) {
        manager.scaningDelegate = self
        manager.scanAllDevices()
        print("START SEARCH")
        sleep(timeout)
        manager.stopScan()
        callback?.searchedDevices(peripherals: peripherals)
    }
    //DeviceScaningDelegate
    internal func scanningStatus(status: Int) {
        DeviceService.getInstance().ls.addLogs(text:String(describing:status))
    }
    func formatMACAddress(_ mac: String) -> String {
        var formattedMAC = ""
        for (index, char) in mac.enumerated() {
            if index % 2 == 0 && index > 0 {
                formattedMAC += ":"
            }
            formattedMAC.append(char)
        }
        return formattedMAC
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
        self.peripheral = peripheral

    }
    internal func onIndicateSuccess() {
         print("Indication successful")
     }
     
    internal func onIndicateFailure(error: Error) {
         print("Indication failure: \(error.localizedDescription)")
     }
     
    internal func onCharacteristicChanged(data: Data) {
        print(data)
     }
    // This method will be triggered once device will be disconnected.
    internal func bleManagerDisConect(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        callback?.onStatusDevice(mac: _identifer!, status: BluetoothStatus.ConnectDisconnect)
    }
    
    //ReadWirteCharteristicDelegate
    internal func bleManagerDidUpdateValueForChar(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        print(characteristic)
    }
    
    internal func bleManagerDidWriteValueForChar(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        print(characteristic)

    }
    
    internal func bleManagerDidUpdateValueForDesc(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
    }
    
    internal func bleManagerDidWriteValueForDesc(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
    }

    //Обработчик:
    internal func bleManagerDidUpdateNotificationState(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        print(characteristic)
        print("Notification")
    }
    
    //ServicesDiscoveryDelegate
    internal func bleManagerDiscoverService (_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        } else {
            DeviceService.getInstance().ls.addLogs(text:"No services found")
        }
    }
    internal func bleManagerDiscoverCharacteristics (_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            callback?.onExpection(mac: peripheral.identifier, ex: error)
            return
        }
        if let characteristics = service.characteristics {
                  for characteristic in characteristics {
                      print(characteristic)
                      if characteristic.uuid.uuidString == "FED6" {
                          print("uuid=")
                          peripheral.setNotifyValue(true, for: characteristic)
                      }
                  }
              }
}

    internal func subscribeToCharacteristic(peripheral: CBPeripheral) {
     
    }
    internal func bleManagerDiscoverDescriptors(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        if let error = error{
            callback?.onExpection(mac: peripheral.identifier, ex: error)
        }
        DeviceService.getInstance().ls.addLogs(text:"bleManagerDiscoverDescriptors")
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
    internal func getMac(device: CBPeripheral){
        let response: Data = String("mac").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    internal func setTime(device: CBPeripheral){
        let timeNow = Date()
        let time = EltaGlucometr.FormatDeviceTime.string(from: timeNow)
        DeviceService.getInstance().ls.addLogs(text:"Settime: " + String(describing:time))
        let response: Data = String("settime." + time).data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    internal func getBattery(device: CBPeripheral){
        let response: Data = String("bat").data(using: .utf8)!
        manager.writeCharacteristicValue(peripheral: device, data: response, char: rxCharacteistic!, type: CBCharacteristicWriteType.withResponse)
    }
    
}
