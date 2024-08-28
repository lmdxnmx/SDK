//
//  FhirObj.swift
//  IoMT.SDK
//
//  Created by Никита on 28.08.2024.
//

import Foundation
public class FhirObj:DataHandler{
var fhirData:String? = nil;
    init(fhirData: String?, code:Int) {
        super.init(code: code)
        self.fhirData = fhirData
    }
   override init(code:Int) {
        super.init(code: code)
       self.fhirData = nil;
    }
}
