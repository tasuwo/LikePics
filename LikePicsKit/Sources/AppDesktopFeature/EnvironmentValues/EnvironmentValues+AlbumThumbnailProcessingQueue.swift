//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import SwiftUI

private struct AlbumThumbnailProcessingQueueKey: EnvironmentKey {
    static let defaultValue = ImageProcessingQueue()
}

extension EnvironmentValues {
    public var albumThumbnailProcessingQueue: ImageProcessingQueue {
        get { self[AlbumThumbnailProcessingQueueKey.self] }
        set { self[AlbumThumbnailProcessingQueueKey.self] = newValue }
    }
}
