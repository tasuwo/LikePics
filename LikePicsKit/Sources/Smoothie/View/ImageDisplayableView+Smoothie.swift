//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public func loadImage(_ request: ImageRequest, with pipeline: Pipeline, on view: ImageDisplayableView, completion: ((ImageResponse?) -> Void)? = nil) {
    ImageLoadTaskController.associateInstance(to: view).loadImage(request, with: pipeline, completion: completion)
}

public func cancelLoadImage(on view: ImageDisplayableView) {
    ImageLoadTaskController.associatingInstance(to: view)?.cancelLoadImage()
}

public extension Smoothie where Base: UIImageView {
    func loadImage(_ request: ImageRequest, with pipeline: Pipeline, completion: ((ImageResponse?) -> Void)? = nil) {
        ImageLoadTaskController.associateInstance(to: base).loadImage(request, with: pipeline, completion: completion)
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