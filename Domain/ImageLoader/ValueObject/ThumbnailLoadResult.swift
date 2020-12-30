//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public enum ThumbnailLoadResult {
    case loaded(UIImage)
    case failedToLoad

    // MARK: - Lifecycle

    init(loadResult: UIImage?) {
        if let image = loadResult {
            self = .loaded(image)
        } else {
            self = .failedToLoad
        }
    }
}
