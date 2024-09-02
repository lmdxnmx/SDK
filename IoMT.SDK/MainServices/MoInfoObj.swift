import Foundation

public class MoInfoObj: DataHandler, Codable {
    public var id: UUID? = nil
    public var address: String? = nil
    public var title: String? = nil
    public var zip: String? = nil
    public var email: String? = nil
    public var phone: String? = nil
    public var region: String? = nil

    // Инициализатор
    init(id: UUID? = nil, address: String? = nil, title: String? = nil, zip: String? = nil, email: String? = nil, phone: String? = nil, region: String? = nil, code: Int) {
        super.init(code: code)
        self.id = id
        self.address = address
        self.title = title
        self.zip = zip
        self.email = email
        self.phone = phone
        self.region = region
    }

    // Инициализатор по умолчанию
    override init(code: Int) {
        super.init(code: code)
    }

    // Реализация Decodable
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
        self.address = try container.decodeIfPresent(String.self, forKey: .address)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.zip = try container.decodeIfPresent(String.self, forKey: .zip)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
        self.region = try container.decodeIfPresent(String.self, forKey: .region)
        super.init(code:0)
    }

    // Реализация Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(zip, forKey: .zip)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(region, forKey: .region)
    
    }

    // Ключи для кодирования и декодирования
    enum CodingKeys: String, CodingKey {
        case id
        case address
        case title
        case zip
        case email
        case phone
        case region
     
    }
}
