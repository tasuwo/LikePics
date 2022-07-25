//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import os.log

public enum LogHandler {
    public static let common = OSLog(subsystem: "net.tasuwo.TBox", category: "common")
    public static let service = OSLog(subsystem: "net.tasuwo.TBox", category: "service")
    public static let storage = OSLog(subsystem: "net.tasuwo.TBox", category: "storage")
    public static let transition: OSLog = {
        // 頻繁に表示されるので、検証時のみオンにする
        // return OSLog(subsystem: "net.tasuwo.TBox", category: "transition")
        return .disabled
    }()

    public static let coreDataStack = OSLog(subsystem: "net.tasuwo.TBox", category: "core-data-stack")
    public static let iCloudSync = OSLog(subsystem: "net.tasuwo.TBox", category: "icloud-sync")
}
