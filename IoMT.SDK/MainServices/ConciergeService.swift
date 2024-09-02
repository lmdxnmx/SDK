//
//  DeviceService.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 06.06.2023.
//

import Foundation
import CoreBluetooth
import CoreData

fileprivate class _baseCallback: ConciergeCallback {
    func onSuccessDiary(id: UUID, status:Int){}
    func onErrorDiary(id: UUID, status: Int){ }
}
private var instanceDS: ConciergeService? = nil

///Основной сервис для взаимодействия с платформой
public class ConciergeService {
    internal var conciergeService: ConciergeService?
    
    internal var _login: String = ""
    
    internal var _password: String = ""
    
    private var _test: Bool = false
    private var _callback: ConciergeCallback = _baseCallback()
    
    public static func getInstance() -> ConciergeService {
        if(instanceDS == nil) {
            return ConciergeService()
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
        DeviceService.getInstance();
        instanceDS = self
    }
    
    ///Создание объекта с указанием авторизационных данных и функции обратного вызова для получения текущего состояния работы сервиса
    public init(login: String, password: String, debug: Bool) {
        BLEManager.getSharedBLEManager().initCentralManager(queue: nil, options: nil)
        _login = login
        _password = password
        _test = debug
        _callback = callbackFunction ?? _baseCallback()
        if(DeviceService.getInstance()._login.isEmpty){
            DeviceService.init(login: _login, password: _password, debug: _test)
        };
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logs = """
        \(timestamp) Параметры конфигурации сервиса:
        SDK инициализировано с следующими параметрами:
        Login: \(_login)
        Password: \(_password)
        Платформа: \(_test ? "https://dev.ppma.ru" : "https://ppma.ru")
        """
        DeviceService.getInstance().ls.addLogs(text: logs)
        instanceDS = self
    }
    
    ///Изменение авторизационных данных при работе сервиса
    public func changeCredentials(login: String, password: String){
        _login = login
        _password = password
        instanceDS = self
    }
    public func getFhirRepresentation(type: String, id: UUID, completion: @escaping (FhirObj?) -> Void) {
        let url = "/concierge/api/fhir/\(type)/\(id)"
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getFhirRepresentation")
        DeviceService.getInstance().im.getFhir(url: url) { result in
            completion(result)
        }
    }

    public func getPmList(completion: @escaping (PmBundle?) -> Void){
        let url:String = "/concierge/api/pm"
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getPmList")
        DeviceService.getInstance().im.getPm(url: url) { result in
            completion(result)
        }
    }
    public func getMoInfo(id:UUID, completion: @escaping (MoInfoObj?) -> Void){
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getMoInfo")
        let url:String = "/concierge/api/mo/\(id.uuidString)"
        DeviceService.getInstance().im.getMoInfo(url: url){ result in
            // Вызываем замыкание completion с результатом запроса
            completion(result)
        }
    }
    public func getObs(year:Int, month:Int, day:Int, completion: @escaping (String?) -> Void){
        let url:String = "/concierge/api/fhir/?year=\(year)&month=\(month)&day=\(day)"
//        DeviceService.getInstance().im.getResource(url: url) { result in
//            // Вызываем замыкание completion с результатом запроса
//            completion(result)
//        }
    }
    public func startSession(phone:String,completion: @escaping (DataHandler?) -> Void){
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.startSession")
        DeviceService.getInstance().im.startSession(phone:phone){ result in
            // Вызываем замыкание completion с результатом запроса
            completion(result)
        }
    }
    public func confirmPhone(code:String,completion: @escaping (DataHandler?)-> Void){
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.confirmPhone")
        let url:String = "/concierge/login/confirmation/\(code)"
        DeviceService.getInstance().im.confirmPhone(url: url){ result in
            // Вызываем замыкание completion с результатом запроса
            completion(result)
        }
    }
    public func getDeviceInfo(id:UUID,completion: @escaping (DeviceInfoObj?) -> Void){
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getDeviceInfo")
        let url:String = "/concierge/api/device/\(id.uuidString)"
        DeviceService.getInstance().im.getDeviceInfo(url: url){ result in
            completion(result)
        }
    }
    public func sendDiary(id:UUID? = nil,derivedFrom: UUID? = nil, subject: UUID, basedOn: UUID,
                          value: [String:String], code: Int, start: Date, finish: Date? = nil,
                          note: String? = nil){
      
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.sendDiary")
        let uuid = id ?? UUID()  // Если id не nil, используем его, иначе создаем новый UUID
        DeviceService.getInstance().im.sendDiary(
            id: uuid,
            sendData: buildObservationJson(
                id: uuid,
                derivedFromStr: derivedFrom,
                subjectStr: subject,
                basedOnStr: basedOn,
                value: value,
                code: code,
                start: start,
                finish: finish,
                note: note
            )!,
            debug: _test
        )

          
        
        }
}

