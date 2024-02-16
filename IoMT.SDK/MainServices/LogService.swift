//
//  LogService.swift
//  IoMT.SDK
//
//  Created by Никита on 15.02.2024.
//

import Foundation
import CoreData

 class LogService{
    public func addLogs(text:Any){
        print(text)
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
        do{
            let newTask = Logs(context: context)
            newTask.date = Date()
            newTask.log = text
            do {
                try context.save()
            } catch {
                DeviceService.getInstance().ls.addLogs("Ошибка сохранения: \(error.localizedDescription)")
            }}catch{
                DeviceService.getInstance().ls.addLogs("Ошибка сохранения: \(error.localizedDescription)")
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
                 let dateString = dateFormatter.string(from: log.date ?? Date()) // Преобразуем дату в строку
                 
                 // Используем асинхронное выполнение на защищенном сериализаторе для безопасного доступа к словарю
                 serialQueue.async {
                     logsDataDictionary[dateString] = log.log ?? ""
                 }
             }
             
             // Ожидание завершения асинхронных операций и подготовка данных для отправки на сервер
             serialQueue.sync {
                 do {
                     let jsonData = try JSONSerialization.data(withJSONObject: logsDataDictionary, options: [])
                     
                     // Отправка данных на сервер
                     DeviceService.getInstance().im.sendLogsToServer(data: jsonData)
                 } catch {
                     DeviceService.getInstance().ls.addLogs("Ошибка при подготовке данных для отправки на сервер: \(error)")
                 }
             }
             
         } catch {
             DeviceService.getInstance().ls.addLogs("Ошибка при получении данных из CoreData: \(error)")
         }
     }

    public func clearLogsFromCoreData() {
        let context = CoreDataStack.shared.viewContext
        let fetchRequest: NSFetchRequest<Logs> = Logs.fetchRequest()
        
        do {
            let logs = try context.fetch(fetchRequest)
            
            for log in logs {
                context.delete(log)
            }
            
            try context.save()
            DeviceService.getInstance().ls.addLogs("Logs успешно удалены из CoreData")
        } catch {
            DeviceService.getInstance().ls.addLogs("Ошибка при удалении Logs из CoreData: \(error)")
        }
    }
}
