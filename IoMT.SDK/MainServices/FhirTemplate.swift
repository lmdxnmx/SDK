//
//  Glucometr.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 08.07.2023.
//

import Foundation

internal class FhirTemplate{
    
    static public func Glucometer(serial: String, model: String,effectiveDateTime: Date, value: Double) -> Data?{
        let uuid: String = UUID().uuidString
        print(uuid)
        let TemplateFhir: String = "{\"entry\":[{\"resource\":{\"code\":{\"coding\":[{\"code\":\"3\",\"display\":\"Измерение глюкозы в капиллярной крови\",\"system\":\"https://ppmp.ru/fhir/VP_OC\",\"userSelected\":false}],\"text\":\"Дистанционное наблюдение за показателями уровня глюкозы крови\"},\"component\":[{\"code\":{\"coding\":[{\"code\":\"4\",\"display\":\"Глюкоза в капиллярной крови натощак\",\"system\":\"https://ppmp.ru/fhir/VP_VT\",\"userSelected\":false}],\"text\":\"Глюкоза в капиллярной крови натощак\"},\"valueQuantity\":{\"code\":\"mmol/l\",\"system\":\"https://ppmp.ru/fhir/VP_MU\",\"unit\":\"ммоль/л\",\"value\":\(value)}}],\"device\":{\"display\":\"\(model)\",\"identifier\":{\"value\":\"\(serial)\"},\"type\":\"Glucometer\"},\"effectiveDateTime\":\"\(EltaGlucometr.FormatPlatformTime.string(from: effectiveDateTime))\",\"resourceType\":\"Observation\"}}],\"id\":\"\(uuid)\",\"resourceType\":\"Bundle\",\"type\":\"collection\"}"
        return Data(TemplateFhir.utf8)
    }
}
