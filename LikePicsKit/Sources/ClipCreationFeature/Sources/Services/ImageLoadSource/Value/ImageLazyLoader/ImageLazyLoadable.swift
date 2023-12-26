//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public protocol ImageLazyLoadable: AnyObject {
    func resolveFilename(_ completion: @escaping (String?) -> Void)
    func resolveFilename() async -> String?
    func load(_ completion: @escaping (Data?) -> Void)
    func load() async -> Data?
}
