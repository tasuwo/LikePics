//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ConsoleLog: Log {
    public enum Level {
        case debug
        case info
        case error
        case critical
    }

    public struct Scope: Equatable {
        let rawValue: String
    }

    public let level: Level
    public let message: String
    public let scope: Scope
    public let function: String
    public let file: String
    public let line: Int

    var fileName: String {
        return (self.file as NSString).lastPathComponent
    }

    public init(level: Level,
                message: String,
                scope: Scope = .default,
                function: String = #function,
                file: String = #file,
                line: Int = #line)
    {
        self.level = level
        self.message = message
        self.scope = scope
        self.function = function
        self.file = file
        self.line = line
    }
}

public extension ConsoleLog.Scope {
    static let `default` = ConsoleLog.Scope("default")
}

public extension ConsoleLog.Scope {
    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
