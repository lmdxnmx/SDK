//
//  LogService.swift
//  IoMT.SDK
//
//  Created by Никита on 15.02.2024.
//

import Foundation
import CoreData

 class LogService{
     public func addLogs(text: String) {
//
//             print(text)
//             let context = CoreDataStack.shared.viewContext
//             let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
//
//             do {
//                 let newTask = Logs(context: context)
//                 newTask.date = Date()
//                 newTask.log = text // Присваиваем строковое значение logText свойству log
//                 do {
//                     try context.save()
//                 } catch {
//                     DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
//                 }
//             } catch {
//                 DeviceService.getInstance().ls.addLogs(text:"Ошибка сохранения: \(error.localizedDescription)")
//             }
//
     }

    public func removeLogs(){
        
    }
     public func sendLogs() {
//         let context = CoreDataStack.shared.viewContext
//         let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
//
//         do {
//             let logs = try context.fetch(fetchRequest)
//
//             // Создаем защищенный сериализатор диспетчера
//             let serialQueue = DispatchQueue(label: "com.example.app.serialQueue")
//
//             // Собираем все логи в словарь данных
//             var logsDataDictionary = [String: String]()
//             let dateFormatter = ISO8601DateFormatter()
//             for log in logs {
//                 print(log)
//                 if let date = log.date {
//                     let dateString = dateFormatter.string(from: date) // Преобразуем дату в строку
//
//                     if let logText = log.log {
//                         logsDataDictionary[dateString] = logText
//                     }
//                 }
//             }
//
//             // Подготавливаем данные для отправки на сервер
//             do {
//                 let jsonData = try JSONSerialization.data(withJSONObject: logsDataDictionary, options: [])
//                 // Отправка данных на сервер
//                 DeviceService.getInstance().im.sendLogsToServer(data: jsonData)
//             } catch {
//                 DeviceService.getInstance().ls.addLogs(text: "Ошибка при подготовке данных для отправки на сервер: \(error)")
//             }
//
//         } catch {
//             DeviceService.getInstance().ls.addLogs(text: "Ошибка при получении данных из CoreData: \(error)")
//         }
     }



    public func clearLogsFromCoreData() {
//        let context = CoreDataStack.shared.viewContext
//        let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
//        
//        do {
//            let logs = try context.fetch(fetchRequest)
//            
//            for log in logs {
//                context.delete(log)
//            }
//            
//            try context.save()
//            DeviceService.getInstance().ls.addLogs(text:"Logs успешно удалены из CoreData")
//        } catch {
//            DeviceService.getInstance().ls.addLogs(text:"Ошибка при удалении Logs из CoreData: \(error)")
//        }
    }
}
