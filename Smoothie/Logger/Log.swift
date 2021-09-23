//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import os.signpost

class Log {
    private let logger: Logger

    // MARK: - Lifecycle

    init(logger: Logger) {
        self.logger = logger
    }

    // MARK: - Methods

    func log(_ type: OSSignpostType, name: StaticString) {
        os_signpost(type, log: logger.log, name: name, signpostID: OSSignpostID(log: logger.log, object: self))
    }
}
