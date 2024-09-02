//
//  PmObj.swift
//  IoMT.SDK
//
//  Created by Никита on 28.08.2024.
//

import Foundation
public class PmObj:Codable{
   public var taskId:UUID? = nil;
   public var deviceId:UUID? = nil;
   public var serviceRequestId:UUID? = nil;
   public var status:String? = nil;
   public var description:String? = nil;
   public var moId:UUID? = nil;
   public var start:Date? = nil;
   public var finish:Date? = nil;
    init(taskId: UUID? = nil, deviceId: UUID? = nil, serviceRequestId: UUID? = nil, status: String? = nil, description: String? = nil, moId: UUID? = nil, start: Date? = nil, finish: Date? = nil) {
        self.taskId = taskId
        self.deviceId = deviceId
        self.serviceRequestId = serviceRequestId
        self.status = status
        self.description = description
        self.moId = moId
        self.start = start
        self.finish = finish
    }
}
 
