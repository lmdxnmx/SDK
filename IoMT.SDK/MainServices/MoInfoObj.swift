//
//  MoInfoObj.swift
//  IoMT.SDK
//
//  Created by Никита on 28.08.2024.
//

import Foundation
public class MoInfoObj:DataHandler{
    var id:UUID? = nil;
    var address:String? = nil;
    var title:String? = nil;
    var zip:String? = nil;
    var email:String? = nil;
    var phone:String? = nil;
    var region:String? = nil;
    init(id: UUID? = nil, address: String? = nil, title: String? = nil, zip: String? = nil, email: String? = nil, phone: String? = nil, region: String? = nil,code:Int) {
        super.init(code: code)
        self.id = id
        self.address = address
        self.title = title
        self.zip = zip
        self.email = email
        self.phone = phone
        self.region = region
    }
   override init(code:Int) {
        super.init(code: code)
        self.id = nil
        self.address = nil
        self.title = nil
        self.zip = nil
        self.email = nil
        self.phone = nil
        self.region = nil
    }
}
