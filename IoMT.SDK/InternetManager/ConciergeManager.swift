import Foundation
import CoreData

private var sharedManager: ConciergeManager? = nil

 class ConciergeManager{
    internal var baseAddress: String
    //Url's variabls
    internal var urlGateWay: URL
    //Encoded login/password
    internal var auth: String
    internal var sdkVersion: String?
    internal var instanceId:UUID
    
    static internal func getManager () -> ConciergeManager {
        if sharedManager == nil {
                   sharedManager = ConciergeManager(login: "", password: "", debug: true)
        }
        return sharedManager!
    }
    var timer: Timer? = nil
    var interval: TimeInterval = 1
     private var isSavingContext = false;
     private var timerIsScheduled = false
    
     internal init(login: String, password: String, debug: Bool) {
        self.auth = Data((login + ":" + password).utf8).base64EncodedString()
        if(!debug){
            baseAddress = "https://ppma.ru"
        }
        else{ baseAddress = "http://test.ppma.ru" }
        self.urlGateWay = URL(string: (self.baseAddress))!
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
    }
     public func getResource(url: String, completion: @escaping (String?) -> Void) {
         let timeUrl = URL(string: (self.baseAddress + url))!
         var urlRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "GET"
         print(timeUrl)
         if let access = UserDefaults.standard.string(forKey: "access_token") {
             urlRequest.addValue("Bearer " + access, forHTTPHeaderField: "Authorization")
         }
         
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")

         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (data, response, error) in
             if let error = error {
                 completion(nil)
                 ConciergeService.getInstance().ls.addLogs(text:"Error: \(error)")
                 return
             }
             
             if let httpResponse = response as? HTTPURLResponse {
                 let statusCode = httpResponse.statusCode
                 if statusCode == 401 {
                     self.refreshToken {
                         self.getResource(url: url, completion: completion)
                     }
                     return
                 }
                 
                 if statusCode <= 202 {
                     if let responseData = data, let responseString = String(data: responseData, encoding: .utf8) {
                         completion(responseString)
                     } else {
                         completion(nil)
                     }
                 } else {
                     completion(nil)
                 }
             } else {
                 completion(nil)
             }
         }
         task.resume()
     }

     public func registration(data:Data){
         let timeUrl  = URL(string: (self.baseAddress + ":8080/concierge/api/user/register"))!
         print(timeUrl)
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "POST"
         urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
         urlRequest.httpBody = data
     
         
         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (data, response, error) in
             if let error = error {
                 ConciergeService.getInstance().ls.addLogs(text:"Error: \(error)")
             }
             if let httpResponse = response as? HTTPURLResponse {
                 let statusCode = httpResponse.statusCode
                 if(statusCode <= 202){
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                 }
                 else{
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                 }
             }
             if let responseData = data {
                 if let responseString = String(data: responseData, encoding: .utf8) {
                     ConciergeService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                 }
             }
         }
         task.resume()
     }
     
     public func resetTokens(phone:String){
         let timeUrl  = URL(string: (self.baseAddress + ":8080/concierge/login/reset"))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "GET"
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
         urlRequest.addValue(phone, forHTTPHeaderField: "phone")
         
         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (data, response, error) in
             if let error = error {
                 ConciergeService.getInstance().ls.addLogs(text:"Error: \(error)")
             }
             if let httpResponse = response as? HTTPURLResponse {
                 let statusCode = httpResponse.statusCode
                 if(statusCode <= 202){
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                 }
                 else{
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                 }
             }
             if let responseData = data {
                 if let responseString = String(data: responseData, encoding: .utf8) {
                     ConciergeService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                 }
             }
         }
         task.resume()
     }
     public func confirmPhone(url:String){
         let timeUrl  = URL(string: (self.baseAddress + url))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "POST"
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
         var status:Int = 500
         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (data, response, error) in
             if let error = error {
                 ConciergeService.getInstance().ls.addLogs(text:"Error: \(error)")
             }
             if let httpResponse = response as? HTTPURLResponse {
                 let statusCode = httpResponse.statusCode
                 if(statusCode <= 202){
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                     status = statusCode
                 }
                 else{
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                     status = statusCode
                 }
             }
             if let responseData = data {
                 if let responseString = String(data: responseData, encoding: .utf8) {
                     if let jsonData = responseString.data(using: .utf8) {
                         do {
                             if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                                 if let accessToken = json["access_token"] as? String,
                                    let refreshToken = json["refresh_token"] as? String {
                                     UserDefaults.standard.set(accessToken, forKey: "access_token")
                                     UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
                                 }
                             }
                         } catch {
                             print("Ошибка при парсинге JSON: \(error.localizedDescription)")
                         }
                     }
                 }
             }
         }
         task.resume()
     }
     public func sendDiary(sendData:Data,debug:Bool){
         let timeUrl  = URL(string: (self.baseAddress + ":8080/concierge/api/pm/observation?debug=\(debug)"))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "PUT"
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.addValue("Id " + self.instanceId.uuidString, forHTTPHeaderField: "InstanceID")
         urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
         if let access = UserDefaults.standard.string(forKey: "access_token"){
             urlRequest.addValue("Bearer " + access, forHTTPHeaderField: "Authorization")
         }
         urlRequest.httpBody = sendData
         print(sendData)
         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (data, response, error) in
             if let error = error {
                 ConciergeService.getInstance().ls.addLogs(text:"Error: \(error)")
             }
             if let httpResponse = response as? HTTPURLResponse {
                 let statusCode = httpResponse.statusCode
                 if statusCode == 401 {
                     self.refreshToken {
                             self.sendDiary(sendData: sendData, debug: debug)
                     }
                     return
                 }
                 if(statusCode <= 202){
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                 }
                 else{
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                 }
             }
             if let responseData = data {
                 if let responseString = String(data: responseData, encoding: .utf8) {
                     ConciergeService.getInstance().ls.addLogs(text:"Response: \(responseString)")
                 }
             }
         }
         task.resume()
     }
     public func refreshToken(completion: @escaping () -> Void){
         let timeUrl  = URL(string: (self.baseAddress + ":8080/concierge/login/access"))!
         var urlRequest: URLRequest = URLRequest(url: timeUrl)
         urlRequest.httpMethod = "GET"
         urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
         urlRequest.addValue("I2024-03-20T10:12:22Z", forHTTPHeaderField: "SDK-VERSION")
         if let refresh = UserDefaults.standard.string(forKey: "refresh_token"){
             urlRequest.addValue(refresh, forHTTPHeaderField: "refreshToken")
         }
         let session = URLSession.shared
         let task = session.dataTask(with: urlRequest) { (data, response, error) in
             if let error = error {
                 ConciergeService.getInstance().ls.addLogs(text:"Error: \(error)")
             }
             if let httpResponse = response as? HTTPURLResponse {
                 let statusCode = httpResponse.statusCode
                 if(statusCode <= 202){
                 }
                 else{
                     ConciergeService.getInstance().ls.addLogs(text:"Status: \(statusCode)")
                 }
             }
             if let responseData = data {
                 if let responseString = String(data: responseData, encoding: .utf8) {
                     if let jsonData = responseString.data(using: .utf8) {
                         do {
                             if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                                 if let accessToken = json["access_token"] as? String{
                                     ConciergeService.getInstance().ls.addLogs(text:"Токен успешно обновлен")
                                     UserDefaults.standard.set(accessToken, forKey: "access_token")
                                     completion()
                                 }
                             }
                         } catch {
                             print("Ошибка при парсинге JSON: \(error.localizedDescription)")
                         }
                     }
                 }
             }
         }
         task.resume()
     }
}
