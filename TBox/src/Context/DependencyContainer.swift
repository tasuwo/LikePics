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

    func makeClipInformationViewController(clip: Clip, item: ClipItem, dataSource: ClipInformationViewDataSource) -> UIViewController

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

    // MARK: Settings

    func makeSettingsViewController() -> UIViewController
}

class DependencyContainer {
    private lazy var logger = RootLogger.shared
    private lazy var clipsStorage = ClipStorage()
    private lazy var userSettingsStorage = UserSettingsStorage()
    private lazy var clipPreviewTransitionController = ClipPreviewTransitioningController()
    private lazy var clipInformationTransitionController = ClipInformationTransitioningController()
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipsListViewController() -> UIViewController {
        let clipsList = ClipsList(clips: [],
                                  visibleHiddenClips: self.userSettingsStorage.fetch().showHiddenItems,
                                  storage: self.clipsStorage,
                                  logger: self.logger)
        let presenter = TopClipsListPresenter(clipsList: clipsList, settingsStorage: self.userSettingsStorage)
        return UINavigationController(rootViewController: TopClipsListViewController(factory: self, presenter: presenter))
    }

    func makeClipPreviewViewController(clip: Clip) -> UIViewController {
        let presenter = ClipPreviewPagePresenter(clip: clip, storage: self.clipsStorage, logger: self.logger)
        let pageViewController = ClipPreviewPageViewController(factory: self,
                                                               presenter: presenter,
                                                               previewTransitionController: self.clipPreviewTransitionController,
                                                               informationTransitionController: self.clipInformationTransitionController)

        let viewController = ClipPreviewViewController(pageViewController: pageViewController)
        viewController.transitioningDelegate = self.clipPreviewTransitionController
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(clip: Clip, item: ClipItem, delegate: ClipItemPreviewViewControllerDelegate) -> ClipItemPreviewViewController {
        let presenter = ClipItemPreviewPresenter(clip: clip, item: item, storage: self.clipsStorage, logger: self.logger)
        let viewController = ClipItemPreviewViewController(factory: self, presenter: presenter)
        viewController.delegate = delegate
        return viewController
    }

    func makeClipInformationViewController(clip: Clip, item: ClipItem, dataSource: ClipInformationViewDataSource) -> UIViewController {
        let presenter = ClipInformationPresenter(clip: clip, item: item)
        let viewController = ClipInformationViewController(factory: self, dataSource: dataSource, presenter: presenter, transitionController: self.clipInformationTransitionController)
        viewController.transitioningDelegate = self.clipInformationTransitionController
        viewController.modalPresentationStyle = .fullScreen
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
        let presenter = SearchEntryPresenter(storage: self.clipsStorage, logger: self.logger)
        return UINavigationController(rootViewController: SearchEntryViewController(factory: self, presenter: presenter, transitionController: self.clipPreviewTransitionController))
    }

    func makeSearchResultViewController(context: SearchContext, clips: [Clip]) -> UIViewController {
        let clipsList = ClipsList(clips: clips,
                                  visibleHiddenClips: self.userSettingsStorage.fetch().showHiddenItems,
                                  storage: self.clipsStorage,
                                  logger: self.logger)
        let presenter = SearchResultPresenter(context: context,
                                              clipsList: clipsList,
                                              settingsStorage: self.userSettingsStorage)
        return SearchResultViewController(factory: self, presenter: presenter)
    }

    func makeAlbumListViewController() -> UIViewController {
        let presenter = AlbumListPresenter(storage: self.clipsStorage, logger: self.logger)
        let viewController = AlbumListViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(album: Album) -> UIViewController {
        let clipsList = ClipsList(clips: album.clips,
                                  visibleHiddenClips: self.userSettingsStorage.fetch().showHiddenItems,
                                  storage: self.clipsStorage,
                                  logger: self.logger)
        let presenter = AlbumPresenter(album: album,
                                       clipsList: clipsList,
                                       settingsStorage: self.userSettingsStorage)
        return AlbumViewController(factory: self, presenter: presenter)
    }

    func makeAddingClipsToAlbumViewController(clips: [Clip], delegate: AddingClipsToAlbumPresenterDelegate?) -> UIViewController {
        let presenter = AddingClipsToAlbumPresenter(sourceClips: clips, storage: self.clipsStorage, logger: self.logger)
        presenter.delegate = delegate
        let viewController = AddingClipsToAlbumViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeTagListViewController() -> UIViewController {
        let presenter = TagListPresenter(storage: self.clipsStorage, logger: self.logger)
        let viewController = TagListViewController(factory: self, presenter: presenter, logger: self.logger)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAddingTagToClipViewController(clips: [Clip], delegate: AddingTagsToClipsPresenterDelegate) -> UIViewController {
        let presenter = AddingTagsToClipsPresenter(clips: clips, storage: self.clipsStorage)
        presenter.delegate = delegate
        let viewController = AddingTagsToClipsViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController() -> UIViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.main)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let presenter = SettingsPresenter(storage: self.userSettingsStorage)
        viewController.factory = self
        viewController.presenter = presenter

        return viewController
    }
}
