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
    public init(login: String, password: String, debug: Bool, callbackFunction:ConciergeCallback? = nil) {
        BLEManager.getSharedBLEManager().initCentralManager(queue: nil, options: nil)
        _login = login
        _password = password
        _test = debug
        _callback = callbackFunction ?? _baseCallback()
        if(DeviceService.getInstance()._login.isEmpty){
            DeviceService.init(login: _login, password: _password, debug: _test)
        };
        DeviceService.getInstance().im.setCallback(_callback: _callback)
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        let logs = """
        \(timestamp) Параметры конфигурации сервиса:
        SDK инициализировано с следующими параметрами:
        Login: \(_login)
        Password: \(_password)
        Платформа: \(_test ? "https://test.ppma.ru" : "https://ppma.ru")
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
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getFhirRepresentation "+type)
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
    public func getObs(id:UUID,timeStart:Date?=nil, timeFinish:Date?=nil,count:Int, page:Int, completion: @escaping (ObservationsBundleHandler?) -> Void){
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getObs")
            let url:String = "/concierge/api/pm/observation/serviceRequest/\(id.uuidString)?timeStart=\(timeStart)&timeFinish=\(timeFinish)&count=\(count)&page=\(page)"
        DeviceService.getInstance().im.getObs(url: url) { result in
                // Вызываем замыкание completion с результатом запроса
                completion(result)
            }
        }
        public func getObs(id:UUID,timeStart:Date?=nil, timeFinish:Date?=nil, completion: @escaping (ObservationsBundleHandler?) -> Void){
            DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getObs")
            let url:String = "/concierge/api/pm/observation/serviceRequest/\(id.uuidString)?timeStart=\(timeStart)&timeFinish=\(timeFinish)&count=0"
            DeviceService.getInstance().im.getObs(url: url) { result in
                // Вызываем замыкание completion с результатом запроса
                completion(result)
            }
        }
    public func startSession(phone:String,completion: @escaping (DataHandler?) -> Void){
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.startSession")
        DeviceService.getInstance().im.startSession(phone:phone){ result in
            // Вызываем замыкание completion с результатом запроса
            completion(result)
        }
    }
    public func finishSession(completion: @escaping (DataHandler?) -> Void){
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.finishSession")
        DeviceService.getInstance().im.finishSession(){ result in
            // Вызываем замыкание completion с результатом запроса
            completion(result)
        }
    }
    public func getSession() -> Bool {
        DeviceService.getInstance().ls.addLogs(text:"Execute method ConciergeService.getSession")
        // Получаем refreshToken из UserDefaults
        guard let refreshToken = UserDefaults.standard.string(forKey: "refresh_token") else {
            return false
        }
        
        // Получаем expireDate из UserDefaults
        guard let expireDateString = UserDefaults.standard.string(forKey: "expire_date"),
              let expireDate = Double(expireDateString) else {
            return false
        }
        
        // Получаем текущее время в миллисекундах
        let dateNow = Date().timeIntervalSince1970 * 1000
        
        // Проверяем наличие токенов и срок действия
        let hasTokens = UserDefaults.standard.string(forKey: "access_token") != nil && !refreshToken.isEmpty
        return hasTokens && dateNow < expireDate
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
    public func getDiaries(id:UUID,timeStart:Date, timeFinish:Date,count:Int, page:Int, completion: @escaping (DiariesBundleHandler?) -> Void){
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getObs")
            let url:String = "/concierge/api/pm/observation/diaries/serviceRequest/\(id.uuidString)?timeStart=\(timeStart)&timeFinish=\(timeFinish)&count=\(count)&page=\(page)"
        DeviceService.getInstance().im.getDiaries(url: url) { result in
                // Вызываем замыкание completion с результатом запроса
                completion(result)
            }
        }
        public func getDiaries(id:UUID,timeStart:Date?=nil, timeFinish:Date?=nil, completion: @escaping (DiariesBundleHandler?) -> Void){
            DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.getObs")
            let url:String = "/concierge/api/pm/observation/diaries/serviceRequest/\(id.uuidString)?timeStart=\(timeStart)&timeFinish=\(timeFinish)&count=10000"
            DeviceService.getInstance().im.getDiaries(url: url) { result in
                // Вызываем замыкание completion с результатом запроса
                completion(result)
            }
        }
//        public func getObs(id:UUID,timeStart:Date, timeFinish:Date, completion: @escaping (String?) -> Void){
//            let url:String = "/concierge/api/pm/observation/\(id.uuidString)?timeStart=\(timeStart)&timeFinish=\(timeFinish)&count=0"
//            cm.getResource(url: url) { result in
//                // Вызываем замыкание completion с результатом запроса
//                completion(result)
//            }
//        }
//        public func getObs(id:UUID,timeStart:Date, timeFinish:Date,count:Int, page:Int, completion: @escaping (String?) -> Void){
//            let url:String = "/concierge/api/pm/observation/\(id.uuidString)?timeStart=\(timeStart)&timeFinish=\(timeFinish)&count=\(count)&page=\(page)"
//            cm.getResource(url: url) { result in
//                // Вызываем замыкание completion с результатом запроса
//                completion(result)
//            }
//        }
    public func sendDiary(id: UUID? = nil, derivedFrom: UUID? = nil, subject: UUID? = nil, basedOn: UUID, value: [String: String], code: Int, start: Date, finish: Date? = nil, note: String? = nil) {
        DeviceService.getInstance().ls.addLogs(text: "Execute method ConciergeService.sendDiary")
        
        let uuid = id ?? UUID()  // Если id не указан, генерируем новый UUID
        // Создаём объект SelfObsObj
        let selfObs = SelfObsObj(
            id: uuid,
            code: String(code),
            subject: subject,
            basedOn: basedOn,
            derivedFrom: derivedFrom,
            start: start,
            finish: finish,
            note: note,
            value: value
        )
        
        // Настраиваем JSONEncoder
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601  // Даты в формате ISO 8601, как в Java
        
        // Сериализуем объект в JSON
        do {
            let jsonData = try encoder.encode(selfObs)
                DeviceService.getInstance().im.sendDiary(
                    id: uuid,
                    sendData: jsonData,
                    debug: false
                )
        } catch {
            print("Ошибка сериализации: \(error)")
        }
    }
}

