//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

private final class TaskManager {
    // MARK: - Properties

    static var associatedKey = "TaskManager.AssociatedKey"

    private var cancellable: ImageLoadTaskCancellable?
    private weak var view: UIImageView?

    // MARK: - Initializers

    init(_ view: UIImageView) {
        self.view = view
    }

    deinit {
        self.cancellable?.cancel()
    }

    // MARK: - Methods

    static func associateInstance(to view: UIImageView) -> TaskManager {
        if let manager = objc_getAssociatedObject(view, &associatedKey) as? TaskManager {
            return manager
        }
        let manager = TaskManager(view)
        objc_setAssociatedObject(view, &associatedKey, manager, .OBJC_ASSOCIATION_RETAIN)
        return manager
    }

    func loadImage(_ request: ImageRequest, with pipeline: Pipeline) {
        self.cancellable?.cancel()
        self.cancellable = nil

        self.cancellable = pipeline.loadImage(request) { image in
            self.view?.image = image
        }
    }
}

extension UIImageView: SmoothieCompatible {}

public extension Smoothie where Base: UIImageView {
    func loadImage(_ request: ImageRequest, with pipeline: Pipeline) {
        TaskManager.associateInstance(to: base).loadImage(request, with: pipeline)
    }
}
