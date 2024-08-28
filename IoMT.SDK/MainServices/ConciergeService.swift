//
//  DeviceService.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 06.06.2023.
//

import Foundation
import CoreBluetooth
import CoreData


private var instanceDS: ConciergeService? = nil

///Основной сервис для взаимодействия с платформой
public class ConciergeService {
    internal var conciergeService: ConciergeService?
    
    internal var _login: String = ""
    
    internal var _password: String = ""
    
    private var _test: Bool = false

    
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
        DeviceService.getInstance();
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
        DeviceService.getInstance().im.getResource(url: url) { result in
            completion(result)
        }
    }

    public func getPmList(completion: @escaping (String?) -> Void){
        let url:String = "/concierge/api/pm"
//        DeviceService.getInstance().im.getResource(url: url) { result in
//            // Вызываем замыкание completion с результатом запроса
//            completion(result)
//        }
    }
    public func getMoInfo(id:UUID, completion: @escaping (String?) -> Void){
        let url:String = "/concierge/api/mo/\(id.uuidString)"
//        DeviceService.getInstance().im.getResource(url: url) { result in
//            // Вызываем замыкание completion с результатом запроса
//            completion(result)
//        }
    }
    public func getObs(year:Int, month:Int, day:Int, completion: @escaping (String?) -> Void){
        let url:String = "/concierge/api/fhir/?year=\(year)&month=\(month)&day=\(day)"
//        DeviceService.getInstance().im.getResource(url: url) { result in
//            // Вызываем замыкание completion с результатом запроса
//            completion(result)
//        }
    }
    public func registration(phone:String, password:String, phoneSecondary:String, email:String){
        DeviceService.getInstance().im.registration(data: ConciergeTemplate.Reg(phone: phone, password: password, phoneSecondary: phoneSecondary, email: email)!)
    }
    public func confirmRegistrationPhone(code:String){
        let url:String = "/concierge/api/user/register/\(code)"
        DeviceService.getInstance().im.confirmPhone(url: url)
    }
    public func confirmLoginPhone(code:String){
        let url:String = "/concierge/login/reset/\(code)"
        DeviceService.getInstance().im.confirmPhone(url: url)
    }
    public func resetTokens(phone:String){
        DeviceService.getInstance().im.resetTokens(phone: phone)
    }
    public func sendDiary(derivedFrom: UUID? = nil, subject: UUID, basedOn: UUID,
                          value: [String:String], code: Int, start: Date, finish: Date? = nil,
                          note: String? = nil){
        DeviceService.getInstance().im.sendDiary(sendData: buildObservationJson(derivedFromStr: derivedFrom, subjectStr: subject, basedOnStr: basedOn, value: value, code: code, start: start, finish: finish, note: note)!, debug:_test)
    }
}

