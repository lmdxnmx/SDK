//
//  SelfObsObj.swift
//  IoMT.SDK
//
//  Created by Никита on 28.08.2024.
//

import Foundation
public class SelfObsObj:Codable{
    public var id: UUID
        public var code: String
        public var subject: String?
        public var basedOn: UUID
        public var derivedFrom: UUID?
        public var start: Date
        public var finish: Date?
        public var note: String?
        public var value: [String: String]
        
        // Инициализация Diary
        init(id: UUID, code: String, subject: String?, basedOn: UUID, derivedFrom: UUID, start: Date, finish: Date, note: String?, value: [String: String]) {
            self.id = id
            self.code = code
            self.subject = subject
            self.basedOn = basedOn
            self.derivedFrom = derivedFrom
            self.start = start
            self.finish = finish
            self.note = note
            self.value = value
        }
}
 
