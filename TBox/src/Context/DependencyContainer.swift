//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence
import TBoxCore
import TBoxUIKit
import UIKit

protocol ViewControllerFactory {
    // MARK: Top

    func makeTopClipsListViewController() -> UIViewController

    // MARK: Preview

    func makeClipPreviewViewController(clip: Clip) -> UIViewController
    func makeClipItemPreviewViewController(clip: Clip, item: ClipItem, delegate: ClipItemPreviewViewControllerDelegate) -> ClipItemPreviewViewController

    // MARK: Selection

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController

    // MARK: Search

    func makeSearchEntryViewController() -> UIViewController
    func makeSearchResultViewController(clips: [Clip]) -> UIViewController

    // MARK: Album

    func makeAlbumListViewController() -> UIViewController
    func makeAlbumViewController(album: Album) -> UIViewController
    func makeAddingClipToAlbumViewController(clip: Clip) -> UIViewController
}

class DependencyContainer {
    private lazy var clipsStorage = ClipStorage()
    private lazy var transitionController = ClipPreviewTransitioningController()
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipsListViewController() -> UIViewController {
        let presenter = TopClipsListPresenter(storage: self.clipsStorage)
        let proxy = TopClipsListPresenterProxy(presenter: presenter)
        return TopClipsListViewController(factory: self, presenter: proxy, transitionController: self.transitionController)
    }

    func makeClipPreviewViewController(clip: Clip) -> UIViewController {
        let presenter = ClipPreviewPagePresenter(clip: clip, storage: self.clipsStorage)
        let pageViewController = ClipPreviewPageViewController(factory: self, presenter: presenter, transitionController: self.transitionController)

        let viewController = ClipPreviewViewController(pageViewController: pageViewController)
        viewController.transitioningDelegate = self.transitionController
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(clip: Clip, item: ClipItem, delegate: ClipItemPreviewViewControllerDelegate) -> ClipItemPreviewViewController {
        let presenter = ClipItemPreviewPresenter(clip: clip, item: item, storage: self.clipsStorage)
        let viewController = ClipItemPreviewViewController(factory: self, presenter: presenter)
        viewController.delegate = delegate
        return viewController
    }

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController {
        let presenter = ClipTargetFinderPresenter(url: clipUrl,
                                                  storage: self.clipsStorage,
                                                  resolver: WebImageResolver(),
                                                  currentDateResovler: { Date() },
                                                  isEnabledOverwrite: isOverwrite)
        let viewController = ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchEntryViewController() -> UIViewController {
        let presenter = SearchEntryPresenter(storage: self.clipsStorage)
        return UINavigationController(rootViewController: SearchEntryViewController(factory: self, presenter: presenter, transitionController: self.transitionController))
    }

    func makeSearchResultViewController(clips: [Clip]) -> UIViewController {
        let presenter = SearchResultPresenter(clips: clips, storage: self.clipsStorage)
        return SearchResultViewController(factory: self, presenter: presenter, transitionController: self.transitionController)
    }

    func makeAlbumListViewController() -> UIViewController {
        let presenter = AlbumListPresenter(storage: self.clipsStorage)
        let viewController = AlbumListViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(album: Album) -> UIViewController {
        let presenter = AlbumPresenter(album: album, storage: self.clipsStorage)
        return AlbumViewController(factory: self, presenter: presenter, transitionController: self.transitionController)
    }

    func makeAddingClipToAlbumViewController(clip: Clip) -> UIViewController {
        let presenter = AddingClipToAlbumPresenter(sourceClip: clip, storage: self.clipsStorage)
        let viewController = AddingClipToAlbumViewController(factory: self, presenter: presenter, transitionController: self.transitionController)
        return UINavigationController(rootViewController: viewController)
    }
}
