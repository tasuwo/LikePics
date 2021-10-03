//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol ImageLoadable: AnyObject {
    func loadData(for source: ImageLoadSource, completion: @escaping (Data?) -> Void)
    func load(from source: ImageLoadSource) -> Future<ImageLoaderResult, ImageLoaderError>
}
