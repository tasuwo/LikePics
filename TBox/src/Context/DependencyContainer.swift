//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    func makeClipsViewController() -> UIViewController
    func makeClipPreviewViewController(clip: Clip) -> UIViewController
    func makeClipItemPreviewViewController(item: ClipItem) -> UIViewController
}

class DependencyContainer {
    private lazy var clipsStorage = ClipStorage()
    private lazy var transitionController = ClipPreviewTransitioningController()
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeClipsViewController() -> UIViewController {
        let presenter = ClipsPresenter(storage: self.clipsStorage)
        return ClipsViewController(factory: self, presenter: presenter, transitionController: self.transitionController)
    }

    func makeClipPreviewViewController(clip: Clip) -> UIViewController {
        let presenter = ClipPreviewPresenter(clip: clip)
        let pageViewController = ClipPreviewPageViewController(factory: self, presenter: presenter, transitionController: self.transitionController)

        let viewController = ClipPreviewViewController(pageViewController: pageViewController)
        viewController.transitioningDelegate = self.transitionController
        // FIXME:
        viewController.modalPresentationStyle = .overFullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(item: ClipItem) -> UIViewController {
        let presenter = ClipPreviewPagePresenter(item: item, storage: self.clipsStorage)
        return ClipItemPreviewViewController(factory: self, presenter: presenter)
    }
}
