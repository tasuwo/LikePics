//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import SwiftUI

private struct AlbumThumbnailProcessingQueueKey: EnvironmentKey {
    static let defaultValue = ImageProcessingQueue()
}

public extension EnvironmentValues {
    var albumThumbnailProcessingQueue: ImageProcessingQueue {
        get { self[AlbumThumbnailProcessingQueueKey.self] }
        set { self[AlbumThumbnailProcessingQueueKey.self] = newValue }
    }
}
