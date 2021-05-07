//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public class RootLogger {
    public static let shared = RootLogger()

    private let internalLoggers: [Loggable]
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Common.TBoxLogger")

    init(loggers: [Loggable] = [ConsoleLogger()]) {
        self.internalLoggers = loggers
    }
}

extension RootLogger: Loggable {
    // MARK: - TBoxLoggable

    public func write(_ log: Log) {
        self.queue.sync {
            self.internalLoggers.forEach { $0.write(log) }
        }
    }
}
