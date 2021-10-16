//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public protocol ImageDataProviding {
    var cacheKey: String { get }

    func load(completion: @escaping (Data?) -> Void)
}
