//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Persistence
import Smoothie
import TBoxCore
import UIKit

protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController
    func makeClipTargetCollectionViewController(webUrl: URL, delegate: ClipCreationDelegate) -> ClipCreationViewController
    func makeClipTargetCollectionViewController(imageProviders: [TBoxCore.ImageProvider],
                                                fileUrls: [URL],
                                                delegate: ClipCreationDelegate) -> ClipCreationViewController
}

class DependencyContainer {
    private let logger: Loggable
    private let clipStore: ClipStorable
    private let tagQueryService: ReferenceTagQueryService
    private let currentDateResolver = { Date() }
    private let tagCommandService: TagCommandService
    private let userSettingsStorage: UserSettingsStorage
    private let thumbnailLoader: ThumbnailLoader

    init() throws {
        let mainBundleUrl = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        guard let mainBundle = Bundle(url: mainBundleUrl) else {
            fatalError("Failed to resolve main bundle.")
        }

        self.logger = RootLogger()
        let imageStorage = try TemporaryImageStorage(configuration: .resolve(for: mainBundle, kind: .group))
        let clipStorage = try TemporaryClipStorage(config: .resolve(for: mainBundle, kind: .group),
                                                   logger: self.logger)
        let referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: mainBundle),
                                                            logger: self.logger)

        self.clipStore = TemporaryClipCommandService(clipStorage: clipStorage,
                                                     imageStorage: imageStorage,
                                                     logger: self.logger)

        self.tagQueryService = try ReferenceTagQueryService(config: .resolve(for: mainBundle),
                                                            logger: self.logger)

        self.tagCommandService = TagCommandService(storage: referenceClipStorage,
                                                   logger: self.logger)

        self.userSettingsStorage = UserSettingsStorage(bundle: mainBundle)

        var config = ThumbnailLoadQueue.Configuration(originalImageLoader: ImageSourceLoader())
        config.diskCache = nil
        config.memoryCache = MemoryCache(config: .default)
        self.thumbnailLoader = ThumbnailLoader(queue: .init(config: config))
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter()
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(webUrl: URL, delegate: ClipCreationDelegate) -> ClipCreationViewController {
        struct Dependency: ClipCreationViewDependency {
            var clipBuilder: ClipBuildable
            var clipStore: ClipStorable
            var imageLoader: ImageLoaderProtocol
            var imageSourceProvider: ImageSourceProvider
            var userSettingsStorage: UserSettingsStorageProtocol
        }
        let dependency = Dependency(clipBuilder: ClipBuilder(),
                                    clipStore: clipStore,
                                    imageLoader: ImageLoader(),
                                    imageSourceProvider: WebImageSourceProvider(url: webUrl),
                                    userSettingsStorage: userSettingsStorage)
        return ClipCreationViewController(factory: self,
                                          state: .init(source: .webImage,
                                                       url: webUrl,
                                                       isSomeItemsHidden: !userSettingsStorage.readShowHiddenItems()),
                                          dependency: dependency,
                                          thumbnailLoader: thumbnailLoader,
                                          delegate: delegate)
    }

    func makeClipTargetCollectionViewController(imageProviders: [TBoxCore.ImageProvider],
                                                fileUrls: [URL],
                                                delegate: ClipCreationDelegate) -> ClipCreationViewController
    {
        struct Dependency: ClipCreationViewDependency {
            var clipBuilder: ClipBuildable
            var clipStore: ClipStorable
            var imageLoader: ImageLoaderProtocol
            var imageSourceProvider: ImageSourceProvider
            var userSettingsStorage: UserSettingsStorageProtocol
        }
        let dependency = Dependency(clipBuilder: ClipBuilder(),
                                    clipStore: clipStore,
                                    imageLoader: ImageLoader(),
                                    imageSourceProvider: LocalImageSourceProvider(providers: imageProviders, fileUrls: fileUrls),
                                    userSettingsStorage: userSettingsStorage)
        return ClipCreationViewController(factory: self,
                                          state: .init(source: .localImage,
                                                       url: nil,
                                                       isSomeItemsHidden: !userSettingsStorage.readShowHiddenItems()),
                                          dependency: dependency,
                                          thumbnailLoader: thumbnailLoader,
                                          delegate: delegate)
    }
}

extension DependencyContainer: TBoxCore.ViewControllerFactory {
    func makeTagSelectionViewController(selectedTags: Set<Domain.Tag.Identity>,
                                        delegate: TagSelectionViewControllerDelegate) -> UIViewController?
    {
        switch self.tagQueryService.queryTags() {
        case let .success(query):
            let viewModel = TagSelectionViewModel(query: query,
                                                  selectedTags: selectedTags,
                                                  commandService: self.tagCommandService,
                                                  settingStorage: self.userSettingsStorage,
                                                  logger: self.logger)
            let viewController = TagSelectionViewController(viewModel: viewModel, delegate: delegate)
            return UINavigationController(rootViewController: viewController)

        case .failure:
            return nil
        }
    }
}

extension TemporaryClipCommandService: ClipStorable {}
