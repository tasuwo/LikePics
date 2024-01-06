//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

public protocol ImageLoadable: AnyObject {
    func data(for source: ImageSource) async -> Data?
    func image(from source: ImageSource) async throws -> LoadedImage
    func load(from source: ImageSource) -> Future<LoadedImage, ImageLoaderError>
}
