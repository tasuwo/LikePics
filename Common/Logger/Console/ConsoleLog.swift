//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct ConsoleLog: Log {
    public enum Level {
        case debug
        case info
        case error
        case critical
    }

    public let level: Level
    public let message: String
    public let function: String
    public let file: String
    public let line: Int

    var fileName: String {
        return (self.file as NSString).lastPathComponent
    }

    public init(level: Level,
                message: String,
                function: String = #function,
                file: String = #file,
                line: Int = #line)
    {
        self.level = level
        self.message = message
        self.function = function
        self.file = file
        self.line = line
    }
}
