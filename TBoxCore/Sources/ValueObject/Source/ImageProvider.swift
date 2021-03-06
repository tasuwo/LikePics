//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol ImageProvider: AnyObject {
    func load(_ completion: @escaping (Data?) -> Void)
}
