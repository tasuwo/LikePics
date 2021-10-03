//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol ImageProvider: AnyObject {
    var fileName: String? { get }
    func load(_ completion: @escaping (Data?) -> Void)
}
