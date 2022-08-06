//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeature
import Combine
import Common
import Domain
import Persistence
import Smoothie
import UIKit

public protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> UIViewController
    func makeClipTargetCollectionViewController(id: UUID, webUrl: URL) -> UIViewController
    func makeClipTargetCollectionViewController(id: UUID, loaders: [ImageLazyLoadable], fileUrls: [URL]) -> UIViewController
}

public class DependencyContainer {
    private let clipStore: ClipStorable
    private let tagQueryService: ReferenceTagQueryService
    private let currentDateResolver = { Date() }
    private let tagCommandService: TagCommandService
    private let userSettingsStorage: UserSettingsStorage
    private let thumbnailPipeline: Pipeline

    public init() throws {
        let mainBundleUrl = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        guard let mainBundle = Bundle(url: mainBundleUrl) else {
            fatalError("Failed to resolve main bundle.")
        }

        let imageStorage = try TemporaryImageStorage(configuration: .resolve(for: mainBundle, kind: .group))
        let clipStorage = try TemporaryClipStorage(config: .resolve(for: mainBundle, kind: .group))
        let referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: mainBundle))

        self.clipStore = TemporaryClipCommandService(clipStorage: clipStorage, imageStorage: imageStorage)

        self.tagQueryService = try ReferenceTagQueryService(config: .resolve(for: mainBundle))

        self.tagCommandService = TagCommandService(storage: referenceClipStorage)

        self.userSettingsStorage = UserSettingsStorage(appBundle: mainBundle)

        var config = Pipeline.Configuration()
        config.diskCache = nil
        config.memoryCache = MemoryCache(config: .default)

        // 発熱させないことを優先し、なるだけ並列処理をさせない
        let singleQueue = OperationQueue()
        singleQueue.maxConcurrentOperationCount = 1
        config.dataLoadingQueue = singleQueue
        config.dataCachingQueue = singleQueue
        config.downsamplingQueue = singleQueue
        config.imageEncodingQueue = singleQueue
        config.imageDecompressingQueue = singleQueue

        self.thumbnailPipeline = Pipeline(config: config)
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    public func makeShareNavigationRootViewController() -> UIViewController {
        let presenter = ShareNavigationRootPresenter()
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    public func makeClipTargetCollectionViewController(id: UUID, webUrl: URL) -> UIViewController {
        struct Dependency: ClipCreationViewDependency {
            var clipRecipeFactory: ClipRecipeFactoryProtocol
            var clipStore: ClipStorable
            var imageLoader: ImageLoadable
            var imageSourceProvider: ImageLoadSourceResolver
            var userSettingsStorage: UserSettingsStorageProtocol
            var modalNotificationCenter: ModalNotificationCenter
        }
        let imageLoader = ImageLoader()
        let dependency = Dependency(clipRecipeFactory: ClipRecipeFactory(),
                                    clipStore: clipStore,
                                    imageLoader: imageLoader,
                                    imageSourceProvider: WebImageLoadSourceResolver(url: webUrl),
                                    userSettingsStorage: userSettingsStorage,
                                    modalNotificationCenter: .default)
        return ClipCreationViewController(factory: self,
                                          state: .init(id: id,
                                                       source: .webImage,
                                                       url: webUrl,
                                                       isSomeItemsHidden: !userSettingsStorage.readShowHiddenItems()),
                                          dependency: dependency,
                                          thumbnailPipeline: thumbnailPipeline,
                                          imageLoader: imageLoader)
    }

    public func makeClipTargetCollectionViewController(id: UUID, loaders: [ImageLazyLoadable], fileUrls: [URL]) -> UIViewController
    {
        struct Dependency: ClipCreationViewDependency {
            var clipRecipeFactory: ClipRecipeFactoryProtocol
            var clipStore: ClipStorable
            var imageLoader: ImageLoadable
            var imageSourceProvider: ImageLoadSourceResolver
            var userSettingsStorage: UserSettingsStorageProtocol
            var modalNotificationCenter: ModalNotificationCenter
        }
        let imageLoader = ImageLoader()
        let dependency = Dependency(clipRecipeFactory: ClipRecipeFactory(),
                                    clipStore: clipStore,
                                    imageLoader: imageLoader,
                                    imageSourceProvider: LocalImageLoadSourceResolver(loaders: loaders, fileUrls: fileUrls),
                                    userSettingsStorage: userSettingsStorage,
                                    modalNotificationCenter: .default)
        return ClipCreationViewController(factory: self,
                                          state: .init(id: id,
                                                       source: .localImage,
                                                       url: nil,
                                                       isSomeItemsHidden: !userSettingsStorage.readShowHiddenItems()),
                                          dependency: dependency,
                                          thumbnailPipeline: thumbnailPipeline,
                                          imageLoader: imageLoader)
    }
}

extension DependencyContainer: ClipCreationFeature.ViewControllerFactory {
    public func makeTagSelectionViewController(selectedTags: Set<Domain.Tag.Identity>,
                                               delegate: TagSelectionViewControllerDelegate) -> UIViewController?
    {
        switch self.tagQueryService.queryTags() {
        case let .success(query):
            let viewModel = TagSelectionViewModel(query: query,
                                                  selectedTags: selectedTags,
                                                  commandService: self.tagCommandService,
                                                  settingStorage: self.userSettingsStorage)
            let viewController = TagSelectionViewController(viewModel: viewModel, delegate: delegate)
            return UINavigationController(rootViewController: viewController)

        case .failure:
            return nil
        }
    }
}

extension TemporaryClipCommandService: ClipStorable {}
