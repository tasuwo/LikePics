//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public func loadImage(_ request: ImageRequest, with processingQueue: ImageProcessingQueue, on view: ImageDisplayableView, completion: ((ImageResponse?) -> Void)? = nil) {
    ImageLoadTaskController.associateInstance(to: view).loadImage(request, with: processingQueue, completion: completion)
}

public func cancelLoadImage(on view: ImageDisplayableView) {
    ImageLoadTaskController.associatingInstance(to: view)?.cancelLoadImage()
}

public extension Smoothie where Base: UIImageView {
    func loadImage(_ request: ImageRequest, with processingQueue: ImageProcessingQueue, completion: ((ImageResponse?) -> Void)? = nil) {
        ImageLoadTaskController.associateInstance(to: base).loadImage(request, with: processingQueue, completion: completion)
    }

    func cancelLoadImage() {
        ImageLoadTaskController.associatingInstance(to: base)?.cancelLoadImage()
    }
}

extension UIImageView: ImageDisplayable {
    open func smt_display(_ image: UIImage?) {
        self.image = image
    }
}

extension UIImageView: SmoothieCompatible {}

#endif
