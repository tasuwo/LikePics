//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public extension UIViewController {
    func dismissAll(completion: (() -> Void)?) {
        dismissAllModals {
            self.dismiss(animated: true, completion: completion)
        }
    }

    func dismissAllModals(completion: (() -> Void)?) {
        var topViewController = self
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        if topViewController === self {
            completion?()
            return
        }

        Self.dismiss(topViewController, until: self) {
            completion?()
        }
    }

    private static func dismiss(_ viewController: UIViewController?,
                                until rootViewController: UIViewController,
                                completion: @escaping () -> Void)
    {
        let presentingViewController = viewController?.presentingViewController
        viewController?.dismiss(animated: true, completion: {
            if viewController === rootViewController {
                completion()
                return
            }

            guard let viewController = presentingViewController else {
                completion()
                return
            }

            self.dismiss(viewController, until: rootViewController, completion: completion)
        })
    }
}
