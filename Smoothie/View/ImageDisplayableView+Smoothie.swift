//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public func loadImage(_ request: ImageRequest, with pipeline: Pipeline, on view: ImageDisplayableView, userInfo: [AnyHashable: Any]? = nil) {
    ImageLoadTaskController.associateInstance(to: view).loadImage(request, with: pipeline, userInfo: userInfo)
}

public extension Smoothie where Base: UIImageView {
    func loadImage(_ request: ImageRequest, with pipeline: Pipeline, userInfo: [AnyHashable: Any]? = nil) {
        ImageLoadTaskController.associateInstance(to: base).loadImage(request, with: pipeline, userInfo: userInfo)
    }
}

extension UIImageView: ImageDisplayable {
    public func smt_willLoad(userInfo: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            self.image = nil
        }
    }

    public func smt_display(_ image: UIImage?, userInfo: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            self.image = image
        }
    }
}

extension UIImageView: SmoothieCompatible {}
