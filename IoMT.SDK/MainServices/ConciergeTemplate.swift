//
//  Glucometr.swift
//  MedicalApp
//
//  Created by Денис Комиссаров on 08.07.2023.
//

import Foundation

internal class ConciergeTemplate{
    
    static public func Reg(phone: String, password: String,phoneSecondary: String, email: String) -> Data?{
        let TemplateReg: String = "{\"phone\":\"\(phone)\",\"password\":\"\(password)\",\"phoneSecondary\":\"\(phoneSecondary)\",\"email\":\"\(email)\",\"fcmToken\":\"\"}"
        print(TemplateReg)
        return Data(TemplateReg.utf8)

    }
}
