//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ThumbnailLoadNotifier {
    struct Target {
        let request: ThumbnailRequest
        weak var observer: ThumbnailLoadObserver?
    }

    var targets: [Target] = []

    // MARK: - Lifecycle

    init(target: Target) {
        self.targets = [target]
    }

    // MARK: - Methods

    func didLoad(image: UIImage?) {
        if let image = image {
            self.targets.forEach { $0.observer?.didSuccessToLoad($0.request, image: image) }
        } else {
            self.targets.forEach { $0.observer?.didFailedToLoad($0.request) }
        }
        self.targets = []
    }
}
