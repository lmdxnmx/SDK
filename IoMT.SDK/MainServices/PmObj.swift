//
//  PmObj.swift
//  IoMT.SDK
//
//  Created by Никита on 28.08.2024.
//

import Foundation
public class PmObj{
    var id:UUID? = nil;
    var deviceId:UUID? = nil;
    var serviceRequestId:UUID? = nil;
    var status:String? = nil;
    var description:String? = nil;
    var moId:UUID? = nil;
    var start:Date? = nil;
    var finish:Date? = nil;
    init(id: UUID? = nil, deviceId: UUID? = nil, serviceRequestId: UUID? = nil, status: String? = nil, description: String? = nil, moId: UUID? = nil, start: Date? = nil, finish: Date? = nil) {
        self.id = id
        self.deviceId = deviceId
        self.serviceRequestId = serviceRequestId
        self.status = status
        self.description = description
        self.moId = moId
        self.start = start
        self.finish = finish
    }
}
