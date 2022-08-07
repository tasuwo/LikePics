//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeature
import Combine
import Common
import Domain
import Environment
import LikePicsUIKit
import Persistence
import Smoothie
import TagSelectionModalFeature
import UIKit

public protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> UIViewController
    func makeClipTargetCollectionViewController(id: UUID, webUrl: URL) -> UIViewController
    func makeClipTargetCollectionViewController(id: UUID, loaders: [ImageLazyLoadable], fileUrls: [URL]) -> UIViewController
}

public class DependencyContainer {
    private weak var rootViewController: UIViewController?

    private let clipStore: ClipStorable
    private let tagQueryService: ReferenceTagQueryService
    private let currentDateResolver = { Date() }
    private let tagCommandService: TagCommandService
    private let userSettingsStorage: UserSettingsStorage
    private let thumbnailPipeline: Pipeline

    public init(rootViewController: UIViewController) throws {
        let mainBundleUrl = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        guard let mainBundle = Bundle(url: mainBundleUrl) else {
            fatalError("Failed to resolve main bundle.")
        }

        self.rootViewController = rootViewController

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

extension DependencyContainer {
    private var topViewController: UIViewController? {
        guard let detailViewController = rootViewController else { return nil }
        var topViewController = detailViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }

    private func isPresentingModal(having id: UUID) -> Bool {
        guard let detailViewController = rootViewController else { return false }

        let isModal = { (id: UUID, viewController: UIViewController) -> Bool in
            if let viewController = viewController as? ModalController {
                return viewController.id == id
            }

            if let viewController = (viewController as? UINavigationController)?.topViewController as? ModalController {
                return viewController.id == id
            }

            return false
        }

        var topViewController = detailViewController
        while let presentedViewController = topViewController.presentedViewController {
            if isModal(id, presentedViewController) { return true }
            topViewController = presentedViewController
        }

        return isModal(id, topViewController)
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
        return ClipCreationViewController(state: .init(id: id,
                                                       source: .webImage,
                                                       url: webUrl,
                                                       isSomeItemsHidden: !userSettingsStorage.readShowHiddenItems()),
                                          dependency: dependency,
                                          thumbnailPipeline: thumbnailPipeline,
                                          imageLoader: imageLoader,
                                          modalRouter: self)
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
        return ClipCreationViewController(state: .init(id: id,
                                                       source: .localImage,
                                                       url: nil,
                                                       isSomeItemsHidden: !userSettingsStorage.readShowHiddenItems()),
                                          dependency: dependency,
                                          thumbnailPipeline: thumbnailPipeline,
                                          imageLoader: imageLoader,
                                          modalRouter: self)
    }
}

extension DependencyContainer: TagSelectionModalRouter {
    // MARK: - TagSelectionModalRouter

    public func showTagSelectionModal(id: UUID, selections: Set<Domain.Tag.Identity>) -> Bool {
        guard isPresentingModal(having: id) == false else { return true }

        struct Dependency: TagSelectionModalDependency {
            var modalNotificationCenter: ModalNotificationCenter
            var tagCommandService: TagCommandServiceProtocol
            var tagQueryService: TagQueryServiceProtocol
            var userSettingStorage: UserSettingsStorageProtocol
        }
        let dependency = Dependency(modalNotificationCenter: .default,
                                    tagCommandService: tagCommandService,
                                    tagQueryService: tagQueryService,
                                    userSettingStorage: userSettingsStorage)

        let state = TagSelectionModalState(id: id,
                                           selections: selections,
                                           isSomeItemsHidden: !userSettingsStorage.readShowHiddenItems())
        let tagAdditionAlertState = TextEditAlertState(title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName)
        let viewController = TagSelectionModalController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         dependency: dependency)

        let navigationViewController = UINavigationController(rootViewController: viewController)

        navigationViewController.modalPresentationStyle = .pageSheet
        navigationViewController.presentationController?.delegate = viewController
        navigationViewController.isModalInPresentation = false

        guard let topViewController = topViewController else { return false }
        topViewController.present(navigationViewController, animated: true, completion: nil)

        return true
    }
}

extension TemporaryClipCommandService: ClipStorable {}
