//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

public protocol ImageLoadable: AnyObject {
    func data(for source: ImageSource) async -> Data?
    func load(from source: ImageSource) -> Future<LoadedImage, ImageLoaderError>
}
