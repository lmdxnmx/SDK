import Foundation

internal class JsonToObj {
    static func decodePmBundle(from data: Data) -> PmBundle? {
        let decoder = JSONDecoder()

        // Реализуем пользовательскую стратегию декодирования даты
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Определяем возможные форматы даты
            let dateFormats = [
                "yyyy-MM-dd'T'HH:mm:ssZ", // формат с секундами
                "yyyy-MM-dd'T'HH:mmZ"     // формат без секунд
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Невозможно декодировать дату: \(dateString)")
        }

        do {
            // Декодируем массив объектов PmObj из JSON
            let pmObjects = try decoder.decode([PmObj].self, from: data)
            // Создаем PmBundle с массивом объектов PmObj
            let pmBundle = PmBundle(bundle: pmObjects, code: 0)
            return pmBundle
        } catch {
            print("Ошибка декодирования: \(error)")
            return nil
        }
    }
    static func decodeDiariesBundle(from data: Data) -> DiariesBundleHandler? {
       let decoder = JSONDecoder()

       // Custom date decoding strategy
       decoder.dateDecodingStrategy = .custom { decoder in
           let container = try decoder.singleValueContainer()
           let dateString = try container.decode(String.self)

           // Possible date formats
           let dateFormats = [
               "yyyy-MM-dd'T'HH:mm:ssZ", // with seconds
               "yyyy-MM-dd'T'HH:mmZ",    // without seconds
               "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // with milliseconds
           ]

           let dateFormatter = DateFormatter()
           dateFormatter.locale = Locale(identifier: "en_US_POSIX")

           for format in dateFormats {
               dateFormatter.dateFormat = format
               if let date = dateFormatter.date(from: dateString) {
                   return date
               }
           }

           throw DecodingError.dataCorruptedError(in: container, debugDescription: "Невозможно декодировать дату: $dateString)")
       }

       do {
           // Decode DiariesBundle from JSON
           let decodedObject = try decoder.decode(DiariesBundle.self, from: data)
           
           // Manually initialize DiariesBundle
           let diariesBundle = DiariesBundle(
               total: decodedObject.total,
               page: decodedObject.page,
               pageSize: decodedObject.pageSize,// Assuming DataHandler has a 'code' property
               diaries: decodedObject.diaries ?? []
           )
           let responseData = DiariesBundleHandler(code: 0, data: diariesBundle)
           return responseData
       } catch {
           print("Decoding error:\(error)")
           return nil
       }
    }
    static func decodeObservations(from data:Data)->ObservationsBundleHandler?{
        let decoder = JSONDecoder()

        // Custom date decoding strategy
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Possible date formats
            let dateFormats = [
                "yyyy-MM-dd'T'HH:mm:ssZ", // with seconds
                "yyyy-MM-dd'T'HH:mmZ",    // without seconds
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // with milliseconds
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Невозможно декодировать дату: $dateString)")
        }

        do {
            // Decode DiariesBundle from JSON
            let decodedObject = try decoder.decode(ObservationsBundle.self, from: data)
            
            // Manually initialize DiariesBundle
            let obsBundle = ObservationsBundle(
                total: decodedObject.total,
                page: decodedObject.page,
                pageSize: decodedObject.pageSize,// Assuming DataHandler has a 'code' property
                observations: decodedObject.observations ?? []
            )
            let responseData = ObservationsBundleHandler(code: 0, data: obsBundle)
            return responseData
        } catch {
            print("Decoding error:\(error)")
            return nil
        }
    }

    static func decodeDeviceInfo(from data: Data) -> DeviceInfoObj? {
           let decoder = JSONDecoder()

           // Реализуем пользовательскую стратегию декодирования даты
           decoder.dateDecodingStrategy = .custom { decoder in
               let container = try decoder.singleValueContainer()
               let dateString = try container.decode(String.self)

               // Определяем формат даты
               let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "dd.MM.yyyy"
               dateFormatter.locale = Locale(identifier: "en_US_POSIX")

               if let date = dateFormatter.date(from: dateString) {
                   return date
               }

               throw DecodingError.dataCorruptedError(in: container, debugDescription: "Невозможно декодировать дату: \(dateString)")
           }

           do {
               // Декодируем объект DeviceInfoObj из JSON
               let deviceInfo = try decoder.decode(DeviceInfoObj.self, from: data)
               return deviceInfo
           } catch {
               print("Ошибка декодирования: \(error)")
               return nil
           }
       }

}
