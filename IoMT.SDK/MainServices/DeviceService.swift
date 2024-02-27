//
//  DeviceService.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 06.06.2023.
//

import Foundation
import CoreBluetooth
import CoreData

fileprivate class _baseCallback: DeviceCallback {
    func onExploreDevice(mac: UUID, atr: Atributes, value: Any){}
    
    func onStatusDevice(mac: UUID, status: BluetoothStatus){ }
    
    func onSendData(mac: UUID, status: PlatformStatus){ }
    
    func onExpection(mac: UUID, ex: Error){ }
    
    func onDisconnect(mac: UUID, data: ([Atributes: Any], Array<Measurements>)){}
    
    func findDevice(peripheral: DisplayPeripheral){}
    
    func searchedDevices(peripherals: [DisplayPeripheral]){}
}

private var instanceDS: DeviceService? = nil

///Основной сервис для взаимодействия с платформой
public class DeviceService {
    internal var deviceService: DeviceService?
    
    internal var _login: String = ""
    
    internal var _password: String = ""
    
    private var _test: Bool = false
    
    internal var im: InternetManager
    internal var rm: ReachabilityManager
    internal var ls: LogService
    private var _callback: DeviceCallback = _baseCallback()
    
    ///Получение экземпляр класса, если до этого он не был иницирован, создаётся пустой объект с базовыми параметрами.
    ///При базовой инициализации login и password - пустые строки, функция обратного вызова, в которой отсутсует любая обработка входящий данных
    public static func getInstance() -> DeviceService {
        if(instanceDS == nil) {
            return DeviceService()
        }
        else{
            return instanceDS!
        }
    }
    
    internal init(){
        if let storedUUIDString = UserDefaults.standard.string(forKey: "instanceId"),
                 let storedUUID = UUID(uuidString: storedUUIDString) {
              } else {
                  let newUUID = UUID()
                  UserDefaults.standard.set(newUUID.uuidString, forKey: "instanceId")
              }
        BLEManager.getSharedBLEManager().initCentralManager(queue: DispatchQueue.global(), options: nil)
        ls = LogService()
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        instanceDS = self
    }
    
    ///Создание объекта с указанием авторизационных данных и функции обратного вызова для получения текущего состояния работы сервиса
    public init(login: String, password: String, callbackFunction: DeviceCallback, debug: Bool){
        BLEManager.getSharedBLEManager().initCentralManager(queue: nil, options: nil)
        _login = login
        _password = password
        _callback = callbackFunction
        _test = debug
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        ls = LogService()
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logs = """
        \(timestamp) Параметры конфигурации сервиса:
        SDK инициализировано с следующими параметрами:
        Login: \(_login)
        Password: \(_password)
        Callback: \(_callback != nil ? "is not nil" : "nil")
        Платформа: \(_test ? "http://test.ppma.ru" : "https://ppma.ru")
        """

        ls.addLogs(text: logs)
        instanceDS = self
    }
    
    ///Изменение авторизационных данных при работе сервиса
    public func changeCredentials(login: String, password: String){
        _login = login
        _password = password
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        instanceDS = self
    }
    
    ///Изменение функции обратного вызова
    public func changeCallback(callbackFunction: DeviceCallback){
        _callback = callbackFunction
    }
    
    ///Организация подключения к устройству.
    ///При подключение к переферийному устройству, требуется шаблонный класс для подключения и объект найденнного устройства
    public func connectToDevice(connectClass: ConnectClass, device: DisplayPeripheral){
        connectClass.callback = self._callback
        let _identifier: UUID = device.peripheral!.identifier
        if(connectClass is AndTonometr){
            if(!AndTonometr.activeExecute) {
                DispatchQueue.global().async {
                    connectClass.connect(device: device.peripheral!)
                }
            }
            else {
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
            }
            return
        }
        if(connectClass is EltaGlucometr){
            if(connectClass.cred == nil){
                self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.NotCorrectPin)
            }else{
                if(!EltaGlucometr.activeExecute) {
                    DispatchQueue.global().async {
                        connectClass.connect(device: device.peripheral!)
                    }
                }
                else {
                    self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.Connected)
                }
            }
            return
        }
        self._callback.onStatusDevice(mac: _identifier, status: BluetoothStatus.InvalidDeviceTemplate)
    }
    
    ///Поиск ble устройств, конечный список записывается в шаблон для подключения
    public func search(connectClass: ConnectClass, timeOut: UInt32){
        DispatchQueue.global().async {
            connectClass.callback = self._callback
            connectClass.search(timeout: timeOut)
        }
    }
    
    public func sendData(connectClass: ConnectClass, serial: String, model: String, time: Date, value: Double)
    {
        if(instanceDS == nil) { return; }
        if(connectClass is EltaGlucometr){
            let postData = FhirTemplate.Glucometer(serial: serial, model: model, effectiveDateTime: time, value: value)
            im.postResource(data: postData!)
        }
    }
    public func applyObservation(connectClass: ConnectClass, serial: String, model: String, time: Date, value: Double)
    {
        if(instanceDS == nil) { return; }
        if(connectClass is EltaGlucometr){
            var identifier = UUID();
            let jsonString = String(data: FhirTemplate.Glucometer(serial: serial, model: model, effectiveDateTime: time, value: value), encoding: .utf8)
            let context = CoreDataStack.shared.viewContext
            let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
            do{
                let existingEntities = try context.fetch(fetchRequest)
                if existingEntities.isEmpty {
                    // Нет существующих объектов с таким же идентификатором, поэтому добавляем новый объект
                    let newTask = Entity(context: context)
                    newTask.title = identifier
                    newTask.body = jsonString
                    do {
                        try context.save()
                    } catch {
                        DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                    }}}catch{
                    DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
                }
        }
    }

    
    ///Отправка данных будет производиться на тестовую площадку <test.ppma.ru>
    public func toTest() {
        _test = true
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        instanceDS = self
    }
    ///Отправка данных будет производиться на основную площадку <ppma.ru>
    public func toProd() {
        _test = false
        im = InternetManager(login: _login, password: _password, debug: _test, callback: _callback)
        rm = ReachabilityManager(manager:im)
        instanceDS = self
    }
   public func getCountOfEntities() -> Int {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
       ls.addLogs(text: "ffaffafgeorov")
        do {
            // Выполняем запрос fetch и получаем массив объектов
            let results = try context.fetch(fetchRequest)
            
            // Получаем количество объектов в массиве
            let count = results.count
           return count
        } catch {
            DeviceService.getInstance().ls.addLogs(text:"Ошибка при выполнении запроса fetch: \(error)")
            return 0
        }
       return 0;
    }
    public func sendLogs(){
        ls.sendLogs();
    }
    public func clearLogs(){
        ls.clearLogsFromCoreData();
    }
    
}

///Структура для сохранения информации об устройтсве
public struct DisplayPeripheral: Hashable {
    public var peripheral: CBPeripheral?
    public var lastRSSI: NSNumber?
    public var isConnectable: Bool?
    public var localName: String?
    
    public func hash(into hasher: inout Hasher) { }

    public static func == (lhs: DisplayPeripheral, rhs: DisplayPeripheral) -> Bool {
        if (lhs.peripheral! == rhs.peripheral) { return true }
        else { return false }
    }
    public init(peripheral: CBPeripheral? = nil, lastRSSI: NSNumber? = nil, isConnectable: Bool? = false, localName: String? = nil) {
        self.peripheral = peripheral
        self.lastRSSI = lastRSSI
        self.isConnectable = isConnectable
        self.localName = localName
    }
}

///Структура для сохранения данных об измерениях
public struct Measurements{
    internal var data: [Atributes: Any] = [:]
    
    init() {
        data = [Atributes: Any]()
    }
    
    public mutating func add(atr: Atributes, value: Any){
        data.updateValue(value, forKey: atr)
    }
    
    public func get() -> [Atributes: Any]?{
        return data
    }
    
    public func get(atr: Atributes) -> Any?{
        return data[atr]
    }
    
}

