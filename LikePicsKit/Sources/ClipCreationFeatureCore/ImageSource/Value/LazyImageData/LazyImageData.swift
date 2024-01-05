//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public protocol LazyImageData: AnyObject {
    func resolveFilename(_ completion: @escaping (String?) -> Void)
    func fileName() async -> String?
    func fetch(_ completion: @escaping (Data?) -> Void)
    func get() async -> Data?
}
