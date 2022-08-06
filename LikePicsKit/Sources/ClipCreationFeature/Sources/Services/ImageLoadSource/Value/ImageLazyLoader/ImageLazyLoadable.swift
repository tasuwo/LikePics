//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public protocol ImageLazyLoadable: AnyObject {
    func resolveFilename(_ completion: @escaping (String?) -> Void)
    func load(_ completion: @escaping (Data?) -> Void)
}
