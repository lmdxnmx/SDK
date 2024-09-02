import Foundation

public class PmBundle: DataHandler, Codable {
    public var bundle: [PmObj]? = nil
    
    init(bundle: [PmObj]?, code: Int) {
        super.init(code: code)
        self.bundle = bundle
    }
    
    required override init(code: Int) {
        super.init(code: code)
        self.bundle = nil
    }
    
    // Реализация Decodable
    required public init(from decoder: Decoder) throws {
        // Декодируем контейнер, который включает и собственные свойства, и свойства суперкласса
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Декодируем свойство bundle
        self.bundle = try container.decode([PmObj]?.self, forKey: .bundle)
        
        // Декодируем свойство responseCode из суперкласса
        let code = try container.decode(Int.self, forKey: .responseCode)
        super.init(code: code)
    }
    
    // Реализация Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Кодируем собственные свойства
        try container.encode(bundle, forKey: .bundle)
        
        // Кодируем свойство responseCode из суперкласса
        try container.encode(responseCode, forKey: .responseCode)
    }
    
    // Ключи для кодирования и декодирования
    enum CodingKeys: String, CodingKey {
        case bundle
        case responseCode
    }
}
