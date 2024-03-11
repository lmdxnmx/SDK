import Foundation
import CoreData

private var sharedManager: InternetManager? = nil

fileprivate class _baseCallback: DeviceCallback {
    func onExploreDevice(mac: UUID, atr: Atributes, value: Any){}
    
    func onStatusDevice(mac: UUID, status: BluetoothStatus){ }
    
    func onSendData(mac: UUID, status: PlatformStatus){ }
    
    func onExpection(mac: UUID, ex: Error){ }
    
    func onDisconnect(mac: UUID, data: ([Atributes: Any], Array<Measurements>)){}
    
    func findDevice(peripheral: DisplayPeripheral){}
    
    func searchedDevices(peripherals: [DisplayPeripheral]){}
}


 class InternetManager{
     private let sendQueue = DispatchQueue(label: "com.example.sendDataQueue", qos: .utility)
    internal var baseAddress: String
    //Url's variabls
    internal var urlGateWay: URL
    //Encoded login/password
    internal var auth: String
    internal var sdkVersion: String?
    internal var instanceId:UUID
    internal var callback: DeviceCallback
    
    static internal func getManager () -> InternetManager {
        if sharedManager == nil {
                   sharedManager = InternetManager(login: "", password: "", debug: true, callback: _baseCallback())
        }
        return sharedManager!
    }
     func scheduleSendDataToServer() {
             sendQueue.asyncAfter(deadline: .now() + interval) { [weak self] in
                 self?.sendDataToServer()
             }
         }
    var timer: Timer? = nil
    var interval: TimeInterval = 1

     private var timerIsScheduled = false
    
     internal init(login: String, password: String, debug: Bool, callback: DeviceCallback) {
        self.auth = Data((login + ":" + password).utf8).base64EncodedString()
        if(!debug){
            baseAddress = "https://ppma.ru"
        }
        else{ baseAddress = "http://test.ppma.ru" }
        self.urlGateWay = URL(string: (self.baseAddress))!
        self.callback = callback
        self.sdkVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
         if let storedUUIDString = UserDefaults.standard.string(forKey: "instanceId"),
            let storedUUID = UUID(uuidString: storedUUIDString) {
             self.instanceId = storedUUID
         }else {
             let newUUID = UUID()
             UserDefaults.standard.set(newUUID.uuidString, forKey: "instanceId")
             self.instanceId = newUUID
         }
        sharedManager = self
        NotificationCenter.default.addObserver(self, selector: #selector(contextDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: CoreDataStack.shared.persistentContainer.viewContext)
    }
     
     @objc func contextDidChange(_ notification: Notification) {
         guard let userInfo = notification.userInfo else { return }
         
         if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
             // Обработ	ка обновленных объектов
         }

         // В вашем методе обработки уведомлений contextDidChange:
         if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
             // Обработка вставленных объектов
             for object in insertedObjects {
                 // Проверяем тип объекта
                 guard let entity = object.entity as? NSEntityDescription, entity.name == "Entity" else {
                     continue
                 }
                 
                 // Действия, если объект типа Entity
                 if self.isCoreDataNotEmpty(){

                     DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                         
                        self.scheduleSendDataToServer()

                 }
             }
         }


         
         if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, !deletedObjects.isEmpty {

             // Обработка удаленных объектов
             for object in deletedObjects {
                 // Проверяем тип объекта
                 guard let entity = object.entity as? NSEntityDescription, entity.name == "Entity" else {
                     continue
                 }
                 
                 // Действия, если объект типа Entity
                 if !self.isCoreDataNotEmpty() && self.timer != nil {
                     self.stopTimer()
                     self.interval = 1
                 }
             }
         }
     }

    
    func isCoreDataNotEmpty() -> Bool {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            DeviceService.getInstance().ls.addLogs(text:"Ошибка при получении объектов из Core Data: \(error)")
            return false
        }
    }
    func stopTimer() {

        self.timer?.invalidate()
        self.timer = nil
    }
    func increaseInterval(){
//            self.stopTimer()
            self.interval = interval*2
//            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendDataToServer), userInfo: nil, repeats: false)
    
    }
    func dropTimer(){
        if(isCoreDataNotEmpty()){
//            self.stopTimer()
            self.interval = 1
            DeviceService.getInstance().ls.addLogs(text:"Таймер сброшен")
            self.scheduleSendDataToServer()
//            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendDataToServer), userInfo: nil, repeats: false)
        }
    }

    
    internal func postResource(identifier: UUID, data: Data) {

        let timeUrl  = URL(string: (self.baseAddress + "/gateway/iiot/api/Observation/data"))!
        print(timeUrl)
        var urlRequest: URLRequest = URLRequest(url: timeUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        //urlRequest
        urlRequest.httpBody = data
        let jsonString = String(data: data, encoding: .utf8)
    
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.callback.onExpection(mac: identifier, ex: error)
                DeviceService.getInstance().ls.addLogs(text:"Error: \(error)")
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
                self.scheduleSendDataToServer()
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if(statusCode <= 202){


                    self.callback.onSendData(mac: identifier, status: PlatformStatus.Success)

                    
                }
                else{
                    if(statusCode != 400 && statusCode != 401  && statusCode != 403){
                        let context = CoreDataStack.shared.viewContext
                        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
                        do{
                        let existingEntities = try context.fetch(fetchRequest)
                        for entity in existingEntities {
                            DeviceService.getInstance().ls.addLogs(text:"Title: \(entity.title?.uuidString ?? "No title"), JSON Body: \(entity.body ?? "No body")")
                            
                        }
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
                        self.scheduleSendDataToServer()
                }
           
                    self.callback.onSendData(mac: identifier, status: PlatformStatus.Failed)
                }
            }
            if let responseData = data {
                if let responseString = String(data: responseData, encoding: .utf8) {
                    DeviceService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                }
            }
        }
        task.resume()
    }
       internal func postResource(data: Data) {
        let timeUrl  = URL(string: (self.baseAddress + "/gateway/iiot/api/Observation/data"))!
        print(timeUrl)
        var urlRequest: URLRequest = URLRequest(url: timeUrl)
        var identifier = UUID();
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = data
        let jsonString = String(data: data, encoding: .utf8)
        var result = urlRequest.allHTTPHeaderFields;
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                self.callback.onExpection(mac: identifier, ex: error)
                
                DeviceService.getInstance().ls.addLogs(text:"Error: \(error)")
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
                self.scheduleSendDataToServer()
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if(statusCode <= 202){
                    self.callback.onSendData(mac: identifier, status: PlatformStatus.Success)
                }
                else{
                    if(statusCode != 400 && statusCode != 401  && statusCode != 403){
                        let context = CoreDataStack.shared.viewContext
                        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
                        do{
                        let existingEntities = try context.fetch(fetchRequest)
                        for entity in existingEntities {
                            DeviceService.getInstance().ls.addLogs(text:"Title: \(entity.title?.uuidString ?? "No title"), JSON Body: \(entity.body ?? "No body")")
                            
                        }
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
                        self.scheduleSendDataToServer()
                }
     
                    self.callback.onSendData(mac: identifier, status: PlatformStatus.Failed)
                }
            }
            if let responseData = data {
                if let responseString = String(data: responseData, encoding: .utf8) {
                    DeviceService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                }
            }
        }
        task.resume()
        
    }
    
     internal func postResource(data: Data,bundle:Bool) {
         let timeUrl  = URL(string: (self.baseAddress + "/gateway/iiot/api/Observation/data"))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         var identifier = UUID();
         urlRequest.httpMethod = "POST"
         urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.httpBody = data
         let jsonString = String(data: data, encoding: .utf8)
         var result = urlRequest.allHTTPHeaderFields;
         
         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (data, response, error) in
             if let error = error {
                 self.callback.onExpection(mac: identifier, ex: error)
                 DeviceService.getInstance().ls.addLogs(text:"Error: \(error)")
              
             }
             if let httpResponse = response as? HTTPURLResponse {
                 let statusCode = httpResponse.statusCode
                 if(statusCode <= 202 || statusCode == 400 || statusCode == 401 || statusCode == 403 || statusCode == 207){
                     let backgroundQueue = DispatchQueue.global(qos: .background)
                     
                     // Помещаем выполнение создания фонового MOC в фоновую очередь
                     backgroundQueue.async {
                         // Создаем фоновый MOC
                         let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                         backgroundContext.persistentStoreCoordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
                         
                         // Начинаем обработку удаления логов
                         let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Entity")
                         fetchRequest.returnsObjectsAsFaults = false
                         do {
                             let results = try backgroundContext.fetch(fetchRequest)
                             for object in results {
                                 guard let objectData = object as? NSManagedObject else { continue }
                                 backgroundContext.delete(objectData)
                             }
                             
                             // Сохраняем изменения в фоновом контексте
                             try backgroundContext.save()
                             
                             self.stopTimer()
                             self.interval = 1
                         } catch let error {
                             print("Delete all data error :", error)
                         }

                     }


                 }
                 else{
                     self.scheduleSendDataToServer()
                     self.callback.onSendData(mac: identifier, status: PlatformStatus.Failed)
                 }
             }
             if let responseData = data {
                 if let responseString = String(data: responseData, encoding: .utf8) {
                     DeviceService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                     
                 }
             }
         }
         task.resume()
         
     }
    internal func getTime(serial: String){
        let timeUrl  = URL(string: (self.baseAddress + "/gateway/iiot/api/Observation/data" + "?serial=\(serial)&type=effectiveDateTime"))!
        var urlRequest: URLRequest = URLRequest(url: timeUrl)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                DeviceService.getInstance().ls.addLogs(text:"Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                
            }
            if let responseData = data {
                if let responseString = String(data: responseData, encoding: .utf8) {
                    let time = EltaGlucometr.FormatPlatformTime.date(from: responseString)
                    EltaGlucometr.lastDateMeasurements = time
                }
            }
        }
        task.resume()
    }
     internal func sendLogsToServer(data: Data) {
         let timeUrl  = URL(string: (self.baseAddress + "/logs/sdk/save"))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "POST"
         urlRequest.addValue("Basic " + self.auth, forHTTPHeaderField: "Authorization")
         urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.httpBody = data
         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (responseData, response, error) in
             if let error = error {
                 DeviceService.getInstance().ls.addLogs(text:"Ошибка при отправке логов на сервер: \(error)")
                 return
             }
             
             guard let httpResponse = response as? HTTPURLResponse else {
                 DeviceService.getInstance().ls.addLogs(text:"Ошибка: Ответ от сервера не является HTTPURLResponse")
                 return
             }
             
             if httpResponse.statusCode <=  202 {
                 // Очищаем только объекты типа Logs из CoreData
                 print("clearLOGS()")
                 DeviceService.getInstance().ls.clearLogsFromCoreData()
             } else {
                 DeviceService.getInstance().ls.addLogs(text:"Ошибка: Не удалось очистить Logs из CoreData. Код ответа сервера: \(httpResponse.statusCode)")
             }
         }
         task.resume()
     }
     @objc func sendDataToServer() {
         DispatchQueue.main.async {
             if(self.isCoreDataNotEmpty()){
                 let context = CoreDataStack.shared.persistentContainer.viewContext
                 let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                 
                 var dataArray: [[Data]] = [] // Массив массивов для сбора данных
                 
                 do {
                     let objects = try context.fetch(fetchRequest)
                     DeviceService.getInstance().ls.addLogs(text: "Попытка отправить: \(String(describing: objects.count)) через \(String(describing:self.interval))")
                     
                     var currentArray: [Data] = [] // Текущий массив данных
                     
                     for (index, object) in objects.enumerated() {
                         if let body = object.body?.data(using: .utf8) {
                             currentArray.append(body) // Добавляем данные в текущий массив
                         } else {
                             DeviceService.getInstance().ls.addLogs(text: "Ошибка: Не удалось преобразовать тело объекта в Data")
                         }
                         
                         if currentArray.count == 35 || index == objects.count - 1 {
                             dataArray.append(currentArray)
                             currentArray = []
                         }
                     }
                     
                     for dataSubArray in dataArray {
                         BundleTemplate.ApplyObservation(dataArray: dataSubArray)
                     }
                 } catch {
                     DeviceService.getInstance().ls.addLogs(text: "Ошибка при получении объектов из Core Data: \(error)")
                 }
                 self.increaseInterval()
             }else{
                 self.stopTimer()
                 self.interval = 1;
             }
         }
   
     }



    
}
