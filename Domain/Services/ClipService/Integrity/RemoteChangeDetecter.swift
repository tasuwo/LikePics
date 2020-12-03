//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol RemoteChangeDetecterDelegate: AnyObject {
    func didDetectChangedTag(_ remoteChangeDetecter: RemoteChangeDetecter)
}

public protocol RemoteChangeDetecter {
    func set(_ delegate: RemoteChangeDetecterDelegate)
    func startObserve(_ cloudStack: CloudStack)
}
