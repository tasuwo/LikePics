//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct Clip {
    public let url: URL
    public let image: UIImage?

    // MARK: - Lifecycle

    public init(url: URL, image: UIImage?) {
        self.url = url
        self.image = image
    }
}
