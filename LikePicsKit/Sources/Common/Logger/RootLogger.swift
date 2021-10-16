//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public class RootLogger {
    private let internalLoggers: [Loggable]

    public init(loggers: [Loggable] = [ConsoleLogger()]) {
        self.internalLoggers = loggers
    }
}

extension RootLogger: Loggable {
    // MARK: - TBoxLoggable

    public func write(_ log: Log) {
        internalLoggers.forEach { $0.write(log) }
    }
}
