//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import os.signpost

class Logger {
    let log: OSLog

    // MARK: - Lifecycle

    init() {
        #if DEBUG
        self.log = OSLog(subsystem: "net.tasuwo.TBox.Smoothie", category: "Thumbnail Loading")
        #else
        self.log = .disabled
        #endif
    }
}
