//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol ImageDataProviding {
    var cacheKey: String { get }

    func load(completion: @escaping (Data?) -> Void)
}
