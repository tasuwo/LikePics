//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension UIImageView: SmoothieCompatible {}

public extension Smoothie where Base: UIImageView {
    func loadImage() {
        TaskManager.associateInstance(to: base).loadImage()
    }
}

private final class TaskManager {
    // MARK: - Properties

    static var associatedKey = "TaskManager.AssociatedKey"

    private weak var view: UIImageView?

    // MARK: - Initializers

    init(_ view: UIImageView) {
        self.view = view
    }

    deinit {
        // TODO: cancel
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

    func loadImage() {
        // TODO: load
    }
}
