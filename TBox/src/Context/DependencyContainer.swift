//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
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

    // MARK: Information

    func makeClipInformationViewController(clip: Clip, item: ClipItem) -> UIViewController

    // MARK: Selection

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController

    // MARK: Search

    func makeSearchEntryViewController() -> UIViewController
    func makeSearchResultViewController(context: SearchContext, clips: [Clip]) -> UIViewController

    // MARK: Album

    func makeAlbumListViewController() -> UIViewController
    func makeAlbumViewController(album: Album) -> UIViewController
    func makeAddingClipsToAlbumViewController(clips: [Clip], delegate: AddingClipsToAlbumPresenterDelegate?) -> UIViewController

    // MARK: Tag

    func makeTagListViewController() -> UIViewController
    func makeAddingTagToClipViewController(clips: [Clip], delegate: AddingTagsToClipsPresenterDelegate) -> UIViewController
}

class DependencyContainer {
    private lazy var logger = RootLogger.shared
    private lazy var clipsStorage = ClipStorage()
    private lazy var transitionController = ClipPreviewTransitioningController()
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipsListViewController() -> UIViewController {
        let presenter = TopClipsListPresenter(storage: self.clipsStorage)
        let proxy = TopClipsListPresenterProxy(presenter: presenter)
        return UINavigationController(rootViewController: TopClipsListViewController(factory: self, presenter: proxy))
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

    func makeClipInformationViewController(clip: Clip, item: ClipItem) -> UIViewController {
        let presenter = ClipInformationPresenter(clip: clip, item: item)
        let viewController = ClipInformationViewController(factory: self, presenter: presenter)
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

    func makeSearchResultViewController(context: SearchContext, clips: [Clip]) -> UIViewController {
        let presenter = SearchResultPresenter(context: context, clips: clips, storage: self.clipsStorage)
        let proxy = SearchResultPresenterProxy(presenter: presenter)
        return SearchResultViewController(factory: self, presenter: proxy)
    }

    func makeAlbumListViewController() -> UIViewController {
        let presenter = AlbumListPresenter(storage: self.clipsStorage, logger: self.logger)
        let viewController = AlbumListViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(album: Album) -> UIViewController {
        let presenter = AlbumPresenter(album: album, storage: self.clipsStorage)
        let proxy = AlbumPresenterProxy(presenter: presenter)
        return AlbumViewController(factory: self, presenter: proxy)
    }

    func makeAddingClipsToAlbumViewController(clips: [Clip], delegate: AddingClipsToAlbumPresenterDelegate?) -> UIViewController {
        let presenter = AddingClipsToAlbumPresenter(sourceClips: clips, storage: self.clipsStorage)
        presenter.delegate = delegate
        let viewController = AddingClipsToAlbumViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeTagListViewController() -> UIViewController {
        let presenter = TagListPresenter(storage: self.clipsStorage)
        let viewController = TagListViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAddingTagToClipViewController(clips: [Clip], delegate: AddingTagsToClipsPresenterDelegate) -> UIViewController {
        let presenter = AddingTagsToClipsPresenter(clips: clips, storage: self.clipsStorage)
        presenter.delegate = delegate
        let viewController = AddingTagsToClipsViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }
}
