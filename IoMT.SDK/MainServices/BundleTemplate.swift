import Foundation

internal class BundleTemplate {
    
    static public func ApplyObservation(dataArray: [Data]){
        var entryArray: [[String: Any]] = []
        
        for data in dataArray {
            if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let entry = jsonData["entry"] as? [[String: Any]] {
                    entryArray.append(contentsOf: entry)
                }
            }
        }
        
        let bundleData: [String: Any] = [
            "resourceType": "Bundle",
            "entry": entryArray
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: bundleData, options: [])
            print(String(data: jsonData,encoding: .utf8))
            DeviceService.getInstance().im.postResource(data: jsonData)
        } catch {
            print("Ошибка кодирования данных в JSON: \(error.localizedDescription)")

        }
    }
}
