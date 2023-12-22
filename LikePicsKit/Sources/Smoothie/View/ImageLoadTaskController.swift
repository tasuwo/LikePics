//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

#if canImport(UIKit)

import UIKit

@objc
public protocol ImageDisplayable {
    @objc
    func smt_display(_ image: UIImage?)
}

public typealias ImageDisplayableView = ImageDisplayable & UIView

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

    func loadImage(_ request: ImageRequest, with pipeline: Pipeline, completion: ((ImageResponse?) -> Void)?) {
        cancelLoadImage()

        cancellable = pipeline.loadImage(request) { [weak self] response in
            DispatchQueue.main.async {
                self?.view?.smt_display(response?.image)
                completion?(response)
            }
        }
    }

    func cancelLoadImage() {
        cancellable?.cancel()
        cancellable = nil
        view?.smt_display(nil)
    }
}

#endif
