
import Foundation


public class ObservationsBundleHandler: DataHandler, Codable {
   public var responseObservationsData: ObservationsBundle? = nil

   init(code: Int, data: ObservationsBundle) {
       super.init(code: code)
       self.responseObservationsData = data
   }

   required override init(code: Int) {
       super.init(code: code)
       self.responseObservationsData = nil
   }

   enum CodingKeys: String, CodingKey {
       case responseObservationsData = "observations"
       case responseCode = "code"
   }

   required public init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)

       self.responseObservationsData = try container.decode(ObservationsBundle?.self, forKey: .responseObservationsData)
       let code = try container.decode(Int.self, forKey: .responseCode)
       super.init(code: code)
   }
   public func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)
       try container.encode(responseObservationsData, forKey: .responseObservationsData)
       try container.encode(responseCode, forKey: .responseCode)
   }
}


public class ObservationsBundle: Codable {
   public var total: String
   public var page: String
   public var pageSize: String
   public var observations: [Observation]?

   enum CodingKeys: String, CodingKey {
       case total
       case page
       case pageSize
       case observations
   }

   init(total: String, page: String, pageSize: String, observations: [Observation]?) {
       self.total = total
       self.page = page
       self.pageSize = pageSize
       self.observations = observations
   }

   required public init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)

       self.total = try container.decode(String.self, forKey: .total)
       self.page = try container.decode(String.self, forKey: .page)
       self.pageSize = try container.decode(String.self, forKey: .pageSize)
       self.observations = try container.decode([Observation].self, forKey: .observations)
   }

   public func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)

       try container.encode(total, forKey: .total)
       try container.encode(page, forKey: .page)
       try container.encode(pageSize, forKey: .pageSize)
       try container.encode(observations, forKey: .observations)
   }
}

public class Observation: Codable {
   public var serviceRequestId: UUID
   public var timeStart: Date
   public var timeFinish: Date
   public var code: String
   public var countObs: String
   public var measurements: [Measurement]? = nil

   enum CodingKeys: String, CodingKey {
       case serviceRequestId
       case timeStart
       case timeFinish
       case code
       case countObs
       case measurements
   }

   init(serviceRequestId: UUID, timeStart: Date, timeFinish: Date, code: String, countObs: String, measurements: [Measurement]) {
       self.serviceRequestId = serviceRequestId
       self.timeStart = timeStart
       self.timeFinish = timeFinish
       self.code = code
       self.countObs = countObs
       self.measurements = measurements
   }

   required public init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)

       self.serviceRequestId = try container.decode(UUID.self, forKey: .serviceRequestId)
       self.timeStart = try container.decode(Date.self, forKey: .timeStart)
       self.timeFinish = try container.decode(Date.self, forKey: .timeFinish)
       self.code = try container.decode(String.self, forKey: .code)
       self.countObs = try container.decode(String.self, forKey: .countObs)
       self.measurements = try container.decode([Measurement].self, forKey: .measurements)
   }

   public func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)

       try container.encode(serviceRequestId, forKey: .serviceRequestId)
       try container.encode(timeStart, forKey: .timeStart)
       try container.encode(timeFinish, forKey: .timeFinish)
       try container.encode(code, forKey: .code)
       try container.encode(countObs, forKey: .countObs)
       try container.encode(measurements, forKey: .measurements)
   }
}

public class Measurement: Codable {
   public var id: UUID
   public var deviceId: UUID
   public var value: [[String: String]]
   public var diaries: [SelfObsObj]? = nil

   enum CodingKeys: String, CodingKey {
       case id
       case deviceId
       case value
       case diaries
   }

   init(id: UUID, deviceId: UUID, value: [[String: String]], diaries: [SelfObsObj]) {
       self.id = id
       self.deviceId = deviceId
       self.value = value
       self.diaries = diaries
   }

   required public init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)

       self.id = try container.decode(UUID.self, forKey: .id)
       self.deviceId = try container.decode(UUID.self, forKey: .deviceId)
       self.value = try container.decode([[String: String]].self, forKey: .value)
       self.diaries = try container.decode([SelfObsObj].self, forKey: .diaries)
   }

   public func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CodingKeys.self)

       try container.encode(id, forKey: .id)
       try container.encode(deviceId, forKey: .deviceId)
       try container.encode(value, forKey: .value)
       try container.encode(diaries, forKey: .diaries)
   }
}

