//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeClipsViewController() -> UIViewController
    func makeClipDetailViewController(clip: Clip) -> UIViewController
    func makeClipPreviewPageViewController(item: ClipItem) -> UIViewController
}

class DependencyContainer {
    private lazy var clipsStorage = ClipStorage()
    private lazy var transitionController = ClipPreviewTransitioningController()
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeClipsViewController() -> UIViewController {
        let presenter = ClipsPresenter(storage: self.clipsStorage)
        let viewController = ClipsViewController(factory: self, presenter: presenter, transitionController: self.transitionController)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.delegate = self.transitionController
        return navigationController
    }

    func makeClipDetailViewController(clip: Clip) -> UIViewController {
        let presenter = ClipPreviewPresenter(clip: clip)
        return ClipPreviewViewController(factory: self, presenter: presenter, transitionController: self.transitionController)
    }

    func makeClipPreviewPageViewController(item: ClipItem) -> UIViewController {
        let presenter = ClipPreviewPagePresenter(item: item, storage: self.clipsStorage)
        return ClipPreviewPageViewController(factory: self, presenter: presenter)
    }
}
