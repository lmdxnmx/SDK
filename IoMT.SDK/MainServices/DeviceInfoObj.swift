import Foundation

// Предположим, что это ваш класс
public class DeviceInfoObj: DataHandler, Codable {
    public var id: UUID?
    public var sn: String?
    public var model: String?
    public var regNumber: String?
    public var regDate: Date?

    // Инициализатор
    init(id: UUID?, sn: String?, model: String?, regNumber: String?, regDate: Date?, code: Int) {
        super.init(code: code)
        self.id = id
        self.sn = sn
        self.model = model
        self.regNumber = regNumber
        self.regDate = regDate
    }

    // Инициализатор по умолчанию
    override init(code: Int) {
        super.init(code: code)
    }

    // Реализация Decodable
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
        self.sn = try container.decodeIfPresent(String.self, forKey: .sn)
        self.model = try container.decodeIfPresent(String.self, forKey: .model)
        self.regNumber = try container.decodeIfPresent(String.self, forKey: .regNumber)
        self.regDate = try container.decodeIfPresent(Date.self, forKey: .regDate)
        
        // Вызываем инициализатор суперкласса с нулевым кодом
        super.init(code: 0)
    }

    // Реализация Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(sn, forKey: .sn)
        try container.encodeIfPresent(model, forKey: .model)
        try container.encodeIfPresent(regNumber, forKey: .regNumber)
        try container.encodeIfPresent(regDate, forKey: .regDate)
    }

    // Ключи для кодирования и декодирования
    enum CodingKeys: String, CodingKey {
        case id
        case sn
        case model
        case regNumber
        case regDate
    }
}


