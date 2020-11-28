//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol CloudStack: AnyObject {
    var isCloudSyncEnabled: Bool { get }
    func reload(isCloudSyncEnabled: Bool)
}
