//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public func loadImage(_ request: ImageRequest, with pipeline: Pipeline, on view: ImageDisplayableView) {
    ImageLoadTaskController.associateInstance(to: view).loadImage(request, with: pipeline)
}

public extension Smoothie where Base: UIImageView {
    func loadImage(_ request: ImageRequest, with pipeline: Pipeline) {
        ImageLoadTaskController.associateInstance(to: base).loadImage(request, with: pipeline)
    }
}

extension UIImageView: ImageDisplayable {
    public func smt_display(_ image: UIImage?) {
        self.image = image
    }
}

extension UIImageView: SmoothieCompatible {}
