//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

@objc
public protocol ImageDisplayable {
    @objc
    func smt_willLoad(userInfo: [AnyHashable: Any]?)

    @objc
    func smt_display(_ image: UIImage?, userInfo: [AnyHashable: Any]?)
}

public typealias ImageDisplayableView = UIView & ImageDisplayable

final class ImageLoadTaskController {
    // MARK: - Properties

    static var associatedKey = "ImageLoadTaskController.AssociatedKey"

    private var cancellable: ImageLoadTaskCancellable?
    private weak var view: ImageDisplayableView?

    // MARK: - Initializers

    init(_ view: ImageDisplayableView) {
        self.view = view
    }

    deinit {
        self.cancellable?.cancel()
    }

    // MARK: - Methods

    static func associateInstance(to view: ImageDisplayableView) -> ImageLoadTaskController {
        if let manager = associatingInstance(to: view) {
            return manager
        }
        let manager = ImageLoadTaskController(view)
        objc_setAssociatedObject(view, &associatedKey, manager, .OBJC_ASSOCIATION_RETAIN)
        return manager
    }

    static func associatingInstance(to view: ImageDisplayableView) -> ImageLoadTaskController? {
        return objc_getAssociatedObject(view, &associatedKey) as? ImageLoadTaskController
    }

    func loadImage(_ request: ImageRequest, with pipeline: Pipeline, userInfo: [AnyHashable: Any]?) {
        cancelLoadImage()

        self.view?.smt_willLoad(userInfo: userInfo)

        if let image = pipeline.config.memoryCache[request.source.cacheKey] {
            view?.smt_display(image, userInfo: userInfo)
            return
        }

        self.cancellable = pipeline.loadImage(request) { [weak self] image in
            self?.view?.smt_display(image, userInfo: userInfo)
        }
    }

    func cancelLoadImage() {
        cancellable?.cancel()
        cancellable = nil
    }
}
