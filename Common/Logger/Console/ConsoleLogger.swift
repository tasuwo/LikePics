//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import os.log

public class ConsoleLogger {
    public static let shared = ConsoleLogger()

    private let scopes: [ConsoleLog.Scope]
    private let osLog: OSLog

    public init(scopes: [ConsoleLog.Scope] = [.default],
                osLog: OSLog = OSLog.default)
    {
        self.scopes = scopes
        self.osLog = osLog
    }
}

extension ConsoleLogger: Loggable {
    // MARK: - TBoxLoggable

    public func write(_ log: Log) {
        guard let log = log as? ConsoleLog else { return }
        guard scopes.contains(log.scope) else { return }
        os_log(log.level.osLogType,
               log: self.osLog,
               "[%@] %@:%@:%d | %@",
               log.level.label,
               log.fileName,
               log.function,
               log.line,
               log.message)
    }
}

private extension ConsoleLog.Level {
    var label: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .error:
            return "ERROR"
        case .critical:
            return "CRITICAL"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug

        case .info:
            return .info

        case .error:
            return .error

        case .critical:
            return .fault
        }
    }
}
