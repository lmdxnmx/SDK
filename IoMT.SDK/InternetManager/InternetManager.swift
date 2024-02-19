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
    var timer: Timer? = nil
    var interval: TimeInterval = 1
    
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
        if self.isCoreDataNotEmpty() {
            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendDataToServer), userInfo: nil, repeats: false)
        }
    }
     @objc func contextDidChange(_ notification: Notification) {
         guard let userInfo = notification.userInfo else { return }
         
         if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
             // Обработка обновленных объектов
         }
         
         if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, !insertedObjects.isEmpty {
             // Обработка вставленных объектов
             for object in insertedObjects {
                 // Проверяем тип объекта
                 guard let entity = object.entity as? NSEntityDescription, entity.name == "Entity" else {
                     continue
                 }
                 
                 // Действия, если объект типа Entity
                 if self.timer == nil && self.isCoreDataNotEmpty() {
                     self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendDataToServer), userInfo: nil, repeats: false)
                     self.sendDataToServer()
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
            self.stopTimer()
            self.interval = interval*2
            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendDataToServer), userInfo: nil, repeats: false)
    
    }
    func dropTimer(){
        if(isCoreDataNotEmpty()){
            self.stopTimer()
            self.interval = 1
            DeviceService.getInstance().ls.addLogs(text:String(describing:interval))
            self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(sendDataToServer), userInfo: nil, repeats: false)
        }
    }

    
    internal func postResource(identifier: UUID, data: Data) {
        let timeUrl  = URL(string: (self.baseAddress + "/gateway/iiot/api/Observation/data"))!
        print(timeUrl)
        var urlRequest: URLRequest = URLRequest(url: timeUrl)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic " + "dXNlcjpwYXNzd29yZA==", forHTTPHeaderField: "Authorization")
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
           
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if(statusCode <= 202){
                    DeviceService.getInstance().ls.addLogs(text:"Status Code: \(statusCode)")
                    let context = CoreDataStack.shared.persistentContainer.viewContext
                    let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                    
                    fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
                    if(self.isCoreDataNotEmpty()){
                        do {
                            let objects = try context.fetch(fetchRequest)
                            for object in objects {
                                context.delete(object)
                            }
                            try context.save()
                        } catch {
                            DeviceService.getInstance().ls.addLogs(text: "Ошибка при удалении объекта из Core Data: \(error)")                }}
                    self.callback.onSendData(mac: identifier, status: PlatformStatus.Success)

                    
                }
                else{
                    let context = CoreDataStack.shared.viewContext
                    let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
                    do{
                        let existingEntities = try context.fetch(fetchRequest)
                        for entity in existingEntities {
                            DeviceService.getInstance().ls.addLogs(text: "Title: \(entity.title?.uuidString ?? "No title"), JSON Body: \(entity.body ?? "No body")")
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
        let jsonString = String(data: data, encoding: .utf8)
        urlRequest.httpBody = data
        
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
     
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if(statusCode <= 202){
                    DeviceService.getInstance().ls.addLogs(text:"Status Code: \(statusCode)")
                    let context = CoreDataStack.shared.persistentContainer.viewContext
                    let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
                    
                    fetchRequest.predicate = NSPredicate(format: "title == %@", identifier as CVarArg)
                    
                    if(self.isCoreDataNotEmpty()){
                        do {
                            let objects = try context.fetch(fetchRequest)
                            for object in objects {
                                context.delete(object)
                            }
                            try context.save()
                        } catch {
                            DeviceService.getInstance().ls.addLogs(text:"Ошибка при удалении объекта из Core Data: \(error)")
                        }}
                    self.callback.onSendData(mac: identifier, status: PlatformStatus.Success)
                }
                else{
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
                DeviceService.getInstance().ls.addLogs(text:"Status Code: \(statusCode)")
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
         let timeUrl  = URL(string: ("http://192.168.181.246" + "/logs/sdk/save"))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "POST"
         urlRequest.addValue("Basic " + "dXNlcjpwYXNzd29yZA==", forHTTPHeaderField: "Authorization")
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
             let context = CoreDataStack.shared.persistentContainer.viewContext
             let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
             
             do {
                 let objects = try context.fetch(fetchRequest)
                 DeviceService.getInstance().ls.addLogs(text: "Попытка отправить: \(String(describing: objects.count)) через \(String(describing:self.interval))")
                 for object in objects {
                     // Проверяем, существует ли у объекта свойство title
                     guard let title = object.title else {
                         DeviceService.getInstance().ls.addLogs(text: "Ошибка: У объекта нет свойства title")
                         continue
                     }
                     self.postResource(identifier: title, data: Data(object.body!.utf8))
                 }
             } catch {
                 DeviceService.getInstance().ls.addLogs(text: "Ошибка при получении объектов из Core Data: \(error)")
             }
             
             self.increaseInterval()
         }
     }


    
}
