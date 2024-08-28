//
//  DeviceInfoObj.swift
//  IoMT.SDK
//
//  Created by Никита on 28.08.2024.
//

import Foundation
 public class DeviceInfoObj:DataHandler{
    var id:UUID? = nil;
    var sn:String? = nil;
    var model:String? = nil;
    var regNumber:String? = nil;
    var date:Date? = nil;
    init(id: UUID?, sn: String?, model: String?, regNumber: String?, date: Date?, code:Int) {
        super.init(code: code)
        self.id = id
        self.sn = sn
        self.model = model
        self.regNumber = regNumber
        self.date = date
    }
   override init(code:Int) {
        super.init(code: code)
        self.id = nil
        self.sn = nil
        self.model = nil
        self.regNumber = nil
        self.date = nil
    }
    }
