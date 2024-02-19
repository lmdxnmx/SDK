//
//  LogService.swift
//  IoMT.SDK
//
//  Created by Никита on 15.02.2024.
//

import Foundation
import CoreData

 class LogService{
     let dateFormatter = DateFormatter()
     public func addLogs(text: String) {
         print(text)
         // Создаем фоновую очередь
         let backgroundQueue = DispatchQueue.global(qos: .background)
         
         // Помещаем выполнение добавления логов в фоновую очередь
         backgroundQueue.async {
             let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
             backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
             
             do {
                 let newLog = Logs(context: backgroundContext)
                 newLog.date = Date()
                 newLog.id = UUID()
                 newLog.log = text
                 
                 do {
                     try backgroundContext.save()
                 } catch {
                     DeviceService.getInstance().ls.addLogs(text: "Ошибка сохранения: \(error.localizedDescription)")
                 }
             } catch {
                 DeviceService.getInstance().ls.addLogs(text: "Ошибка сохранения: \(error.localizedDescription)")
             }
         }
     }



    public func removeLogs(){
        
    }
     public func sendLogs() {
         // Создаем фоновую очередь
         let backgroundQueue = DispatchQueue.global(qos: .background)
         
         // Помещаем выполнение отправки логов на сервер в фоновую очередь
         backgroundQueue.async {
             let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
             backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
             
             let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Logs")
             fetchRequest.returnsObjectsAsFaults = false
             
             do {
                 let logs = try context.fetch(fetchRequest)
                 
                 // Создаем словарь для хранения данных о логах
                 var logsDataDictionary = [String: String]()
                 let dateFormatter = ISO8601DateFormatter()
                 
                 // Заполняем словарь данными о логах
                 for log in logs {
                     if let date = log.date, let logText = log.log {
                         let dateString = dateFormatter.string(from: date)
                         logsDataDictionary[dateString] = logText
                     }
                 }
                 
                 // Подготавливаем данные для отправки на сервер
                 do {
                     let jsonData = try JSONSerialization.data(withJSONObject: logsDataDictionary, options: [])
                     
                     print(logsDataDictionary)
                     // Отправляем данные на сервер
                     DeviceService.getInstance().im.sendLogsToServer(data: jsonData)
                 } catch {
                     print("Ошибка при подготовке или отправке данных на сервер: \(error)")
                 }
                 
             } catch {
                 print("Ошибка при получении данных из CoreData: \(error)")
             }
         }
     }





     public func clearLogsFromCoreData() {
         // Создаем фоновую очередь
         let backgroundQueue = DispatchQueue.global(qos: .background)
         
         // Помещаем выполнение создания фонового MOC в фоновую очередь
         backgroundQueue.async {
             // Создаем фоновый MOC
             let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
             backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
             
             // Начинаем обработку удаления логов
             let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Logs")
             fetchRequest.returnsObjectsAsFaults = false
             do {
                 let results = try backgroundContext.fetch(fetchRequest)
                 for object in results {
                     guard let objectData = object as? NSManagedObject else { continue }
                     backgroundContext.delete(objectData)
                 }
                 
                 // Сохраняем изменения в фоновом контексте
                 try backgroundContext.save()
                 
                 // Выводим сообщение об успешном удалении логов
                 print("Logs cleared successfully")
             } catch let error {
                 print("Delete all data error :", error)
             }
             print("4")
         }
         print("clearLOGS")
     }




}
