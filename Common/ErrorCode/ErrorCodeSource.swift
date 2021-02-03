//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum ErrorCodeFactor {
    case string(String)
    case number(Int)
}

public protocol ErrorCodeSource {
    var factors: [ErrorCodeFactor] { get }
}

public extension ErrorCodeSource {
    func makeErrorCode() -> String {
        let factors: [String] = self.factors.map { factor in
            switch factor {
            case let .string(value):
                return "\(value)"
            case let .number(value):
                return "\(value)"
            }
        }
        return factors.joined(separator: "-")
    }
}
