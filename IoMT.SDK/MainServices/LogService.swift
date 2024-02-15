//
//  LogService.swift
//  IoMT.SDK
//
//  Created by Никита on 15.02.2024.
//

import Foundation
import CoreData

 class LogService{
    internal var baseAddress: String
    internal var apiAddress: String
    //Url's variabls
    internal var urlGateWay: URL
    //Encoded login/password
//    internal var auth: String
    internal var sdkVersion: String?
     internal var instanceId:UUID
     internal init(debug: Bool) {
        apiAddress = "/logs/sdk/save"
        if(!debug){
            baseAddress = "https://ppma.ru"
        }
        else{ baseAddress = "http://test.ppma.ru" }
         if let storedUUIDString = UserDefaults.standard.string(forKey: "instanceId"),
            let storedUUID = UUID(uuidString: storedUUIDString) {
             self.instanceId = storedUUID
         } else {
            print("instance не найден")
         }
        self.urlGateWay = URL(string: (self.baseAddress + self.apiAddress))!
        self.sdkVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    public func addLogs(text:String){
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
        do{
            // Нет существующих объектов с таким же идентификатором, поэтому добавляем новый объект
            let newTask = Logs(context: context)
            newTask.date = Date()
            newTask.log = text
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения: \(error.localizedDescription)")
            }}catch{
                print("Ошибка сохранения: \(error.localizedDescription)")
            }
    }
    public func removeLogs(){
        
    }
     public func sendLogs(){
         let context = CoreDataStack.shared.viewContext
         let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
        
         do {
             let logs = try context.fetch(fetchRequest)
            
             // Собираем все логи в словарь данных
             var logsDataDictionary = [String: Any]()
             let dateFormatter = ISO8601DateFormatter()
             for log in logs {
                 let dateString = dateFormatter.string(from: log.date ?? Date()) // Преобразуем дату в строку
                 logsDataDictionary[dateString] = log.log ?? ""
             }
            
             // Подготовка данных для отправки на сервер
             let jsonData = try JSONSerialization.data(withJSONObject: logsDataDictionary, options: [])
            
             // Отправка данных на сервер
             sendLogsToServer(data: jsonData)
            
         } catch {
             print("Ошибка при получении данных из CoreData: \(error)")
         }
     }


    
    private func sendLogsToServer(data: Data) {
        var urlRequest: URLRequest = URLRequest(url: self.urlGateWay)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic " + "dXNlcjpwYXNzd29yZA==", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = data
        print(self.urlGateWay)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (responseData, response, error) in
            if let error = error {
                print("Ошибка при отправке логов на сервер: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Ошибка: Ответ от сервера не является HTTPURLResponse")
                return
            }
            
            if httpResponse.statusCode <=  200 {
                // Очищаем только объекты типа Logs из CoreData
                self.clearLogsFromCoreData()
            } else {
                print("Ошибка: Не удалось очистить Logs из CoreData. Код ответа сервера: \(httpResponse.statusCode)")
            }
        }
        task.resume()
    }

    private func clearLogsFromCoreData() {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
        
        do {
            let logs = try context.fetch(fetchRequest)
            
            for log in logs {
                context.delete(log)
            }
            
            try context.save()
            print("Logs успешно удалены из CoreData")
        } catch {
            print("Ошибка при удалении Logs из CoreData: \(error)")
        }
    }
}
