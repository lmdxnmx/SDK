//
//  DiariesObj.swift
//  IoMT.SDK
//
//  Created by Никита on 22.03.2025.
//

import Foundation

public class DiariesBundle: Codable {
    public var total: Int
    public var page: Int
    public var pageSize: Int
    public var diaries: [SelfObsObj]? = nil
    
    init(total: Int, page: Int, pageSize: Int, diaries: [SelfObsObj]?) {
        self.total = total
        self.page = page
        self.pageSize = pageSize
        self.diaries = diaries
    }
    
    // Реализация Decodable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Декодируем поля total, page и pageSize
        self.total = try container.decode(Int.self, forKey: .total)
        self.page = try container.decode(Int.self, forKey: .page)
        self.pageSize = try container.decode(Int.self, forKey: .pageSize)
        
        // Декодируем массив diaries
        self.diaries = try container.decode([SelfObsObj]?.self, forKey: .diaries)
    }
    
    // Реализация Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Кодируем поля total, page и pageSize
        try container.encode(total, forKey: .total)
        try container.encode(page, forKey: .page)
        try container.encode(pageSize, forKey: .pageSize)
        
        // Кодируем массив diaries
        // Кодируем свойство responseCode из суперкласса
        try container.encode(diaries, forKey: .diaries)
       
    }
    
    // Ключи для кодирования и декодирования
    enum CodingKeys: String, CodingKey {
        case total
        case page
        case pageSize
        case diaries
    }
}
public class DiariesBundleHandler: DataHandler,Codable {
    public var responseDiariesData:DiariesBundle? = nil
    
    init(code:Int,data:DiariesBundle) {
        super.init(code: code)
        self.responseDiariesData = data;
    }
    
    required override init(code: Int) {
        super.init(code: code)
        self.responseDiariesData = nil
    }
    
    // Реализация Decodable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Декодируем массив diaries
        self.responseDiariesData = try container.decode(DiariesBundle?.self, forKey: .responseDiariesData)
        let code = try container.decode(Int.self, forKey: .responseCode)
        super.init(code: code)
    }
    
    // Реализация Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(responseDiariesData, forKey: .responseDiariesData)
        try container.encode(responseCode, forKey: .responseCode)
    }
    
    // Ключи для кодирования и декодирования
    enum CodingKeys: String, CodingKey {
        case responseDiariesData
        case responseCode
    }
}
