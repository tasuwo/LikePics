//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum CloudAvailability: Equatable {
    case available(Context)
    case unavailable

    public enum Context: String, Equatable, Codable {
        case none
        case accountChanged = "account_changed"
    }

    public var isAvailable: Bool {
        switch self {
        case .available:
            return true

        case .unavailable:
            return false
        }
    }
}

extension CloudAvailability: Codable {
    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case available
        case unavailable
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .available:
            let context = try container.decode(Context.self, forKey: .available)
            self = .available(context)

        case .unavailable:
            self = .unavailable

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .available(context):
            try container.encode(context, forKey: .available)

        case .unavailable:
            try container.encode(true, forKey: .unavailable)
        }
    }
}
