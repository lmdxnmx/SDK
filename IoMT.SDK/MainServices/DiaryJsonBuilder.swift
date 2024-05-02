import Foundation

func buildObservationJson(derivedFromStr: UUID?, subjectStr: UUID, basedOnStr: UUID,
                          value: [String:String], code: Int, start: Date, finish: Date?, note: String?) -> Data? {
    let uuid = UUID().uuidString
    var observation: [String:Any] = [:]
    var categoryArray: [[String:Any]] = []
    var categoryObject: [String:Any] = [:]
    var codingObject: [String:Any] = [:]
    var codingArrayCode: [[String:Any]] = []
    var codingObjectCode: [String:Any] = [:]
    var codeObject: [String:Any] = [:]
    var codingArrayForCode: [[String:Any]] = []
    var codingObjectForCode: [String:Any] = [:]
    var basedOnArray: [[String:Any]] = []
    var basedOnObject: [String:Any] = [:]
    var subject: [String:Any] = [:]
    var derivedFrom: [[String:Any]] = []
    var derivedFromObj: [String:Any] = [:]
    var componentArray: [[String:Any]] = []
    var componentObject: [String:Any] = [:]
    var codeObjectForComponent: [String:Any] = [:]
    var codingArrayForComponent: [[String:Any]] = []
    var codingObjectForComponent: [String:Any] = [:]
    var valueQuantity: [String:Any] = [:]
    var effectivePeriod: [String:Any] = [:]
    var noteArray: [[String:Any]] = []
    var noteObject: [String:Any] = [:]
    var valueStringObject: [String:Any] = [:]

    do {
        codingObjectCode["system"] = "http://hl7.org/fhir/ValueSet/observation-category"
        if code == 5 {
            codingObjectCode["code"] = "activity"
            codingObjectCode["display"] = "Activity"
        } else if code == 9 {
            codingObjectCode["code"] = "survey"
            codingObjectCode["display"] = "Survey"
        } else if code == 4 || code == 6 {
            codingObjectCode["code"] = "therapy"
            codingObjectCode["display"] = "Therapy"
        }
        codingArrayCode.append(codingObjectCode)
        codingObject["coding"] = codingArrayCode
        categoryObject["coding"] = codingArrayCode
        categoryArray.append(categoryObject)

        if code == 4 {
            codingObjectForCode["system"] = "[valSetUrl]/fhir/VP_OC"
            codingObjectForCode["code"] = code
            codingObjectForCode["display"] = "Дневник питания"
            codingObjectForCode["userSelected"] = "false"
            codingArrayForCode.append(codingObjectForCode)
            codeObject["coding"] = codingArrayForCode
            codeObject["text"] = "Дневник питания"
            // Handle code 4 specifics...
        } else if code == 5 {
            codingObjectForCode["system"] = "[valSetUrl]/fhir/VP_OC"
            codingObjectForCode["code"] = code
            codingObjectForCode["display"] = "Дневник физической активности"
            codingObjectForCode["userSelected"] = "false"
            codingArrayForCode.append(codingObjectForCode)
            codeObject["coding"] = codingArrayForCode
            codeObject["text"] = "Дневник физической активности"
            // Handle code 5 specifics...
        } else if code == 6 {
            codingObjectForCode["system"] = "[valSetUrl]/fhir/VP_OC"
            codingObjectForCode["code"] = code
            codingObjectForCode["display"] = "Мониторинг приема медикаментов"
            codingObjectForCode["userSelected"] = "false"
            codingArrayForCode.append(codingObjectForCode)
            codeObject["coding"] = codingArrayForCode
            codeObject["text"] = "Мониторинг приема медикаментов"
            // Handle code 6 specifics...
        } else if code == 9 {
            codingObjectForCode["system"] = "[valSetUrl]/fhir/VP_OC"
            codingObjectForCode["code"] = code
            codingObjectForCode["display"] = "Анкета пациента"
            codingObjectForCode["userSelected"] = "false"
            codingArrayForCode.append(codingObjectForCode)
            codeObject["coding"] = codingArrayForCode
            codeObject["text"] = "Анкета пациента"
            // Handle code 9 specifics...
        }

        observation["resourceType"] = "Observation"
        observation["id"] = uuid
        observation["status"] = "final"
        observation["category"] = categoryArray
        observation["code"] = codeObject
        let dateFormatter = ISO8601DateFormatter()
        if finish == nil {
            observation["effectiveDateTime"] = dateFormatter.string(from: start)
        } else {
            effectivePeriod["start"] =  dateFormatter.string(from: start)
            effectivePeriod["end"] =  dateFormatter.string(from: finish!)
            observation["effectivePeriod"] = effectivePeriod
        }
        if note != nil {
            noteObject["text"] = note
            noteArray.append(noteObject)
            observation["note"] = noteArray
        }

        basedOnObject["reference"] = "ServiceRequest/" + basedOnStr.uuidString
        basedOnArray.append(basedOnObject)
        observation["basedOn"] = basedOnArray

        subject["reference"] = "Patient/" + subjectStr.uuidString
        observation["subject"] = subject
        if derivedFromStr != nil {
            derivedFromObj["reference"] = "Observation/" + derivedFromStr!.uuidString
            derivedFrom.append(derivedFromObj)
            observation["derivedFrom"] = derivedFrom
        }
        if code == 4 {
            for (key, tab) in value {
                var codingObjectForComponentCopy: [String:Any] = [:]
                var codeObjectForComponentCopy: [String:Any] = [:]
                var codingArrayForComponentCopy: [[String:Any]] = []
                var valueQuantityCopy: [String:Any] = [:]
                var componentObjectCopy: [String:Any] = [:]
                if key == "BreadUnit" {
                    codingObjectForComponentCopy["code"] = 5
                    codingObjectForComponentCopy["display"] = "Хлебная (углеводная) единица"
                    codeObjectForComponentCopy["text"] = "Хлебная (углеводная) единица"
                    codingArrayForComponentCopy.append(codingObjectForComponentCopy)
                    
                    codeObjectForComponentCopy["coding"] = codingArrayForComponentCopy
                    valueQuantityCopy["system"] = "[valSetUrl]/fhir/VP_MU"
                    valueQuantityCopy["code"] = "U"
                    
                    componentObjectCopy["code"] = codeObjectForComponentCopy
                    componentObjectCopy["valueQuantity"] = valueQuantityCopy
                    codingObjectForComponentCopy["system"] = "[valSetUrl]/fhir/VP_VT"
                    valueQuantityCopy["value"] = tab
                    componentArray.append(componentObjectCopy)
                } else if key == "Carbohydrates" {
                    codingObjectForComponentCopy["code"] = 17
                    codingObjectForComponentCopy["display"] = "Углеводы"
                    codeObjectForComponentCopy["text"] = "Углеводы"
                    codingArrayForComponentCopy.append(codingObjectForComponentCopy)
                    
                    codeObjectForComponentCopy["coding"] = codingArrayForComponentCopy
                    valueQuantityCopy["system"] = "[valSetUrl]/fhir/VP_MU"
                    valueQuantityCopy["code"] = "g"
                    componentObjectCopy["code"] = codeObjectForComponentCopy
                    componentObjectCopy["valueQuantity"] = valueQuantityCopy
                    codingObjectForComponentCopy["system"] = "[valSetUrl]/fhir/VP_VT"
                    valueQuantityCopy["value"] = tab
                    componentArray.append(componentObjectCopy)
                } else if key == "Proteins" {
                    codingObjectForComponentCopy["code"] = 15
                    codingObjectForComponentCopy["display"] = "Белки"
                    codeObjectForComponentCopy["text"] = "Белки"
                    codingArrayForComponentCopy.append(codingObjectForComponentCopy)
                    
                    codeObjectForComponentCopy["coding"] = codingArrayForComponentCopy
                    valueQuantityCopy["system"] = "[valSetUrl]/fhir/VP_MU"
                    valueQuantityCopy["code"] = "g"
                    
                    componentObjectCopy["code"] = codeObjectForComponentCopy
                    componentObjectCopy["valueQuantity"] = valueQuantityCopy
                    codingObjectForComponentCopy["system"] = "[valSetUrl]/fhir/VP_VT"
                    valueQuantityCopy["value"] = tab
                    componentArray.append(componentObjectCopy)
                } else if key == "Fats" {
                    codingObjectForComponentCopy["code"] = 16
                    codingObjectForComponentCopy["display"] = "Жиры"
                    codeObjectForComponentCopy["text"] = "Жиры"
                    codingArrayForComponentCopy.append(codingObjectForComponentCopy)
                    
                    codeObjectForComponentCopy["coding"] = codingArrayForComponentCopy
                    valueQuantityCopy["system"] = "[valSetUrl]/fhir/VP_MU"
                    valueQuantityCopy["code"] = "g"
                    
                    componentObjectCopy["code"] = codeObjectForComponentCopy
                    componentObjectCopy["valueQuantity"] = valueQuantityCopy
                    codingObjectForComponentCopy["system"] = "[valSetUrl]/fhir/VP_VT"
                    valueQuantityCopy["value"] = tab
                    componentArray.append(componentObjectCopy)
                }
            }
            observation["component"] = componentArray
        } else if code == 5 {
            var codingObjectForComponent: [String:Any] = [:]
            var codeObjectForComponent: [String:Any] = [:]
            var codingArrayForComponent: [[String:Any]] = []
            var componentObject: [String:Any] = [:]
            codingObjectForComponent["code"] = 40
            codingObjectForComponent["system"] = "[valSetUrl]/fhir/VP_VT"
            codingObjectForComponent["display"] = "Физическая активность"
            codingArrayForComponent.append(codingObjectForComponent)
            codeObjectForComponent["coding"] = codingArrayForComponent
            codeObjectForComponent["text"] = "Физическая активность"
            componentObject["code"] = codeObjectForComponent
            for (key, tab) in value {
                if value.count > 1 {
                    valueStringObject[key] = tab
                } else {
                    observation["valueString"] = key + " " + tab
                }
            }
            if value.count > 1 {
                observation["valueString"] = valueStringObject.description
            }
        } else if code == 6 {
            var codingObjectForComponent: [String:Any] = [:]
            var codeObjectForComponent: [String:Any] = [:]
            var codingArrayForComponent: [[String:Any]] = []
            var componentObject: [String:Any] = [:]
            codingObjectForComponent["code"] = 21
            codingObjectForComponent["system"] = "[valSetUrl]/fhir/VP_VT"
            codingObjectForComponent["display"] = "Приём медикаментов"
            codingArrayForComponent.append(codingObjectForComponent)
            codeObjectForComponent["coding"] = codingArrayForComponent
            codeObjectForComponent["text"] = "Приём медикаментов"
            componentObject["code"] = codeObjectForComponent
            for (key, tab) in value {
                if value.count > 1 {
                    valueStringObject[key] = tab
                } else {
                    observation["valueString"] = key + " " + tab
                }
            }
            if value.count > 1 {
                observation["valueString"] = valueStringObject.description
            }
        } else if code == 9 {
            // Код для code == 9
            for (key, tab) in value {
                if value.count > 1 {
                    valueStringObject[key] = tab
                } else {
                    observation["valueString"] = key + " " + tab
                }
            }
            if value.count > 1 {
                observation["valueString"] = valueStringObject.description
            }
        }


        let jsonData = try JSONSerialization.data(withJSONObject: observation, options: [])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("JSON: \(jsonString)")
        }
        return jsonData
    } catch {
        print(error.localizedDescription)
    }
    return nil
}
