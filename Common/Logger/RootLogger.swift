//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public class RootLogger {
    public static let shared = RootLogger()

    private let internalLoggers: [TBoxLoggable]
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Common.TBoxLogger")

    init(loggers: [TBoxLoggable] = [ConsoleLogger()]) {
        self.internalLoggers = loggers
    }
}

extension RootLogger: TBoxLoggable {
    // MARK: - TBoxLoggable

    public func write(_ log: TBoxLog) {
        self.queue.sync {
            self.internalLoggers.forEach { $0.write(log) }
        }
    }
}
