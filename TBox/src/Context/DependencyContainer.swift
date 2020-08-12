//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeClipPreviewTransitionableNavigationController(root viewController: UIViewController) -> UINavigationController
    func makeClipsViewController() -> ClipsViewController
    func makeClipDetailViewController(clip: Clip) -> ClipPreviewViewController
    func makeClipPreviewPageViewController(item: ClipItem) -> ClipPreviewPageViewController
}

class DependencyContainer {
    private lazy var clipsStorage = ClipStorage()
    private lazy var transitionController = ClipPreviewTransitioningController()
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeClipPreviewTransitionableNavigationController(root viewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.delegate = self.transitionController
        return navigationController
    }

    func makeClipsViewController() -> ClipsViewController {
        let presenter = ClipsPresenter(storage: self.clipsStorage)
        return ClipsViewController(factory: self, presenter: presenter, transitionController: self.transitionController)
    }

    func makeClipDetailViewController(clip: Clip) -> ClipPreviewViewController {
        let presenter = ClipPreviewPresenter(clip: clip)
        return ClipPreviewViewController(factory: self, presenter: presenter, transitionController: self.transitionController)
    }

    func makeClipPreviewPageViewController(item: ClipItem) -> ClipPreviewPageViewController {
        let presenter = ClipPreviewPagePresenter(item: item)
        return ClipPreviewPageViewController(factory: self, presenter: presenter)
    }
}
