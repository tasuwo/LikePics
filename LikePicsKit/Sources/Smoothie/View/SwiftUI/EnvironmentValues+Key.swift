//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

private struct ImageProcessingQueueKey: EnvironmentKey {
    static let defaultValue = ImageProcessingQueue()
}

extension EnvironmentValues {
    public var imageProcessingQueue: ImageProcessingQueue {
        get { self[ImageProcessingQueueKey.self] }
        set { self[ImageProcessingQueueKey.self] = newValue }
    }
}
