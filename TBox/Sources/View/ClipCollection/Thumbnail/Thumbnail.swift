//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

enum Thumbnail {
    case loaded(UIImage)
    case loading
    case failedToLoad
    case noImage

    init(loaded: UIImage?) {
        if let image = loaded {
            self = .loaded(image)
        } else {
            self = .failedToLoad
        }
    }
}
