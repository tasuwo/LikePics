//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import SwiftUI

private struct ClipThumbnailProcessingQueueKey: EnvironmentKey {
    static let defaultValue = ImageProcessingQueue()
}

public extension EnvironmentValues {
    var clipThumbnailProcessingQueue: ImageProcessingQueue {
        get { self[ClipThumbnailProcessingQueueKey.self] }
        set { self[ClipThumbnailProcessingQueueKey.self] = newValue }
    }
}
