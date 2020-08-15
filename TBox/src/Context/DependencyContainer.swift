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
    func makeClipItemPreviewViewController(clip: Clip, item: ClipItem, delegate: ClipItemPreviewViewControllerDelegate) -> UIViewController
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
        let presenter = ClipPreviewPagePresenter(clip: clip, storage: self.clipsStorage)
        let pageViewController = ClipPreviewPageViewController(factory: self, presenter: presenter, transitionController: self.transitionController)

        let viewController = ClipPreviewViewController(pageViewController: pageViewController)
        viewController.transitioningDelegate = self.transitionController
        // FIXME:
        viewController.modalPresentationStyle = .overFullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(clip: Clip, item: ClipItem, delegate: ClipItemPreviewViewControllerDelegate) -> UIViewController {
        let presenter = ClipItemPreviewPresenter(clip: clip, item: item, storage: self.clipsStorage)
        let viewController = ClipItemPreviewViewController(factory: self, presenter: presenter)
        viewController.delegate = delegate
        return viewController
    }
}
