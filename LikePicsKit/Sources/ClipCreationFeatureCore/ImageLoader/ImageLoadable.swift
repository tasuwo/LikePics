//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

public protocol ImageLoadable: AnyObject {
    func data(for source: ImageLoadSource) async -> Data?
    func loadData(for source: ImageLoadSource, completion: @escaping (Data?) -> Void)
    func load(from source: ImageLoadSource) -> Future<ImageLoaderResult, ImageLoaderError>
}
