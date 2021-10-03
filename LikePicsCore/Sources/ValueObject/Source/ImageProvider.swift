//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol ImageProvider: AnyObject {
    func resolveFilename(_ completion: @escaping (String?) -> Void)
    func load(_ completion: @escaping (Data?) -> Void)
}
