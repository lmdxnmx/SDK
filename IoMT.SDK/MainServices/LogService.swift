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
         // Создаем экземпляр DateFormatter
         let dateFormatter = DateFormatter()
         // Устанавливаем формат даты и времени, включая миллисекунды
         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

         print(text)
         let context = CoreDataStack.shared.viewContext
         let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
         
         do {
             let newLog = Logs(context: context)
             newLog.date = Date() // Устанавливаем текущую дату и время
             newLog.log = text
             
             do {
                 try context.save()
             } catch {
                 DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
             }
         } catch {
             DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
         }
     }


    public func removeLogs(){
        
    }
     public func sendLogs() {
         let context = CoreDataStack.shared.viewContext
         let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()

         do {
             let logs = try context.fetch(fetchRequest)

             // Создаем защищенный сериализатор диспетчера
             let serialQueue = DispatchQueue(label: "com.example.app.serialQueue")

             // Собираем все логи в словарь данных
             var logsDataDictionary = [String: String]()
             let dateFormatter = ISO8601DateFormatter()
             for log in logs {
                 print(log)
                 if let date = log.date {
                     let dateString = dateFormatter.string(from: date) // Преобразуем дату в строку

                     if let logText = log.log {
                         logsDataDictionary[dateString] = logText
                     }
                 }
             }

             // Подготавливаем данные для отправки на сервер
             do {
                 let jsonData = try JSONSerialization.data(withJSONObject: logsDataDictionary, options: [])
                 // Отправка данных на сервер
                 DeviceService.getInstance().im.sendLogsToServer(data: jsonData)
             } catch {
                 DeviceService.getInstance().ls.addLogs(text: "Ошибка при подготовке данных для отправки на сервер: \(error)")
             }

         } catch {
             DeviceService.getInstance().ls.addLogs(text: "Ошибка при получении данных из CoreData: \(error)")
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
             } catch let error {
                 print("Delete all data error :", error)
             }
         }
     }



}
