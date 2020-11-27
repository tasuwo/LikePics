//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import Persistence
import TBoxCore
import TBoxUIKit
import UIKit

// swiftlint:disable implicitly_unwrapped_optional

class DependencyContainer {
    // MARK: - Properties

    // MARK: Storage

    private var clipStorage: NewClipStorage!
    private let tmpClipStorage: ClipStorageProtocol
    private let referenceClipStorage: ReferenceClipStorageProtocol
    private var imageStorage: NewImageStorage!
    private let tmpImageStorage: ImageStorageProtocol
    private var thumbnailStorage: ThumbnailStorageProtocol!
    private let userSettingsStorage: UserSettingsStorageProtocol = UserSettingsStorage()

    // MARK: Service

    private var clipCommandService: (ClipCommandServiceProtocol & ClipStorable)!
    private var clipQueryService: ClipQueryService!
    private var imageQueryService: NewImageQueryService!
    private(set) var integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol!
    private(set) var persistService: TemporaryClipsPersistServiceProtocol!

    // MARK: Core Data

    private var persistentContainer: NSPersistentCloudKitContainer!
    private var imageQueryContext: NSManagedObjectContext!
    private var commandContext: NSManagedObjectContext!

    // MARK: Queue

    private let clipCommandQueue = DispatchQueue(label: "net.tasuwo.TBox.ClipCommand")
    private let imageQueryQueue = DispatchQueue(label: "net.tasuwo.TBox.ImageQuery")

    // MARK: Logger

    private let logger: TBoxLoggable

    // MARK: - Lifecycle

    init() throws {
        self.tmpImageStorage = try ImageStorage(configuration: .resolve(for: Bundle.main, kind: .group))
        self.logger = RootLogger.shared
        self.tmpClipStorage = try ClipStorage(config: .resolve(for: Bundle.main, kind: .group), logger: self.logger)
        self.referenceClipStorage = try ReferenceClipStorage(config: .resolve(for: Bundle.main), logger: self.logger)

        try self.setupCoreDataStack(iCloudSyncEnabled: true, isInitial: true)

        self.clipCommandService = ClipCommandService(clipStorage: self.clipStorage,
                                                     referenceClipStorage: referenceClipStorage,
                                                     imageStorage: self.imageStorage,
                                                     thumbnailStorage: self.thumbnailStorage,
                                                     logger: self.logger,
                                                     queue: self.clipCommandQueue)
        self.integrityValidationService = ClipReferencesIntegrityValidationService(clipStorage: self.clipStorage,
                                                                                   referenceClipStorage: self.referenceClipStorage,
                                                                                   logger: self.logger,
                                                                                   queue: self.clipCommandQueue)
        self.persistService = TemporaryClipsPersistService(temporaryClipStorage: self.tmpClipStorage,
                                                           temporaryImageStorage: self.tmpImageStorage,
                                                           clipStorage: self.clipStorage,
                                                           referenceClipStorage: self.referenceClipStorage,
                                                           imageStorage: self.imageStorage,
                                                           logger: self.logger,
                                                           queue: self.clipCommandQueue)
    }

    // MARK: - Methods

    func setupCoreDataStack(iCloudSyncEnabled: Bool, isInitial: Bool) throws {
        let newContainer: NSPersistentCloudKitContainer = {
            let container = PersistentContainerLoader.load()

            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

            if !iCloudSyncEnabled {
                description.cloudKitContainerOptions = nil
            }

            container.loadPersistentStores(completionHandler: { _, error in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            container.viewContext.automaticallyMergesChangesFromParent = true

            return container
        }()

        let newImageQueryContext: NSManagedObjectContext = {
            return self.imageQueryQueue.sync {
                let context = newContainer.newBackgroundContext()
                return context
            }
        }()

        let newCommandContext: NSManagedObjectContext = {
            return self.clipCommandQueue.sync {
                let context = newContainer.newBackgroundContext()
                return context
            }
        }()

        self.persistentContainer = newContainer
        self.imageQueryContext = newImageQueryContext
        self.commandContext = newCommandContext

        if isInitial {
            self.clipStorage = NewClipStorage(context: newCommandContext)
            self.imageStorage = NewImageStorage(context: newCommandContext)

            self.clipQueryService = ClipQueryService(context: newContainer.viewContext)
            self.imageQueryService = NewImageQueryService(context: newImageQueryContext)
            self.thumbnailStorage = try ThumbnailStorage(queryService: self.imageQueryService, bundle: Bundle.main)
        } else {
            self.clipCommandQueue.sync {
                self.clipStorage.context = newCommandContext
                self.imageStorage.context = newCommandContext
            }

            self.clipQueryService.context = newContainer.viewContext
            self.imageQueryService.context = newImageQueryContext
        }
    }
}

extension DependencyContainer: CoreDataStackContainer {
    // MARK: - CoreDataStackContainer

    func reloadStack(isICloudSyncEnabled: Bool) {
        try! self.setupCoreDataStack(iCloudSyncEnabled: isICloudSyncEnabled, isInitial: false)
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipsListViewController() -> UIViewController? {
        let query: ClipListQuery
        switch self.clipQueryService.queryAllClips() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TopClipsListView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TopClipsListPresenter(query: query,
                                              clipService: self.clipCommandService,
                                              cacheStorage: self.thumbnailStorage,
                                              settingStorage: self.userSettingsStorage,
                                              logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .top, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        let viewController = TopClipsListViewController(factory: self,
                                                        presenter: presenter,
                                                        clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                                        navigationItemsProvider: navigationItemsProvider,
                                                        toolBarItemsProvider: toolBarItemsProvider)

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewViewController(clipId: Domain.Clip.Identity) -> UIViewController? {
        let query: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipPreviewView for clip having clip id \(clipId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipPreviewPagePresenter(query: query,
                                                 clipCommandService: self.clipCommandService,
                                                 logger: self.logger)

        let barItemsPresenter = ClipPreviewPageBarButtonItemsPresenter(dataSource: presenter)
        let barItemsProvider = ClipPreviewPageBarButtonItemsProvider(presenter: barItemsPresenter)

        let previewTransitioningController = ClipPreviewTransitioningController(logger: self.logger)
        let informationTransitioningController = ClipInformationTransitioningController(logger: self.logger)

        let pageViewController = ClipPreviewPageViewController(
            factory: self,
            presenter: presenter,
            barItemsProvider: barItemsProvider,
            previewTransitioningController: previewTransitioningController,
            informationTransitionController: informationTransitioningController
        )

        let viewController = ClipPreviewViewController(pageViewController: pageViewController)
        viewController.transitioningDelegate = previewTransitioningController
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

    func makeClipItemPreviewViewController(clipId: Domain.Clip.Identity, itemId: ClipItem.Identity) -> ClipItemPreviewViewController? {
        let query: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipItemPreviewView for clip having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipItemPreviewPresenter(query: query,
                                                 itemId: itemId,
                                                 imageQueryService: self.imageQueryService,
                                                 thumbnailStorage: self.thumbnailStorage,
                                                 logger: self.logger)

        let viewController = ClipItemPreviewViewController(factory: self, presenter: presenter)

        return viewController
    }

    func makeClipInformationViewController(clipId: Domain.Clip.Identity,
                                           itemId: ClipItem.Identity,
                                           transitioningController: ClipInformationTransitioningControllerProtocol,
                                           dataSource: ClipInformationViewDataSource) -> UIViewController?
    {
        let query: ClipQuery
        switch self.clipQueryService.queryClip(having: clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open ClipInformationPresenter for clip having clip id \(clipId), item id \(itemId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = ClipInformationPresenter(query: query,
                                                 itemId: itemId,
                                                 clipCommandService: self.clipCommandService,
                                                 logger: self.logger)

        let viewController = ClipInformationViewController(factory: self,
                                                           dataSource: dataSource,
                                                           presenter: presenter,
                                                           transitioningController: transitioningController)
        viewController.transitioningDelegate = transitioningController
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }

    func makeClipTargetCollectionViewController(clipUrl: URL, delegate: ClipTargetFinderDelegate, isOverwrite: Bool) -> UIViewController {
        let presenter = ClipTargetFinderPresenter(url: clipUrl,
                                                  clipStore: self.clipCommandService,
                                                  currentDateResolver: { Date() },
                                                  isEnabledOverwrite: isOverwrite)
        let viewController = ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchEntryViewController() -> UIViewController {
        let presenter = SearchEntryPresenter()
        let viewController = SearchEntryViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchResultViewController(context: SearchContext) -> UIViewController? {
        let query: ClipListQuery
        switch context {
        case let .keywords(values):
            switch self.clipQueryService.queryClips(matchingKeywords: values) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for keywords \(values). (\(error.rawValue))
                """))
                return nil
            }

        case let .tag(value):
            switch self.clipQueryService.queryClips(tagged: value) {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for tag \(value). (\(error.rawValue))
                """))
                return nil
            }

        case .uncategorized:
            switch self.clipQueryService.queryUncategorizedClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to open SearchResultView for uncategorized clips. (\(error.rawValue))
                """))
                return nil
            }
        }

        let presenter = SearchResultPresenter(context: context,
                                              query: query,
                                              clipCommandService: self.clipCommandService,
                                              cacheStorage: self.thumbnailStorage,
                                              settingStorage: self.userSettingsStorage,
                                              logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .searchResult, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        return SearchResultViewController(factory: self,
                                          presenter: presenter,
                                          clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                          navigationItemsProvider: navigationItemsProvider,
                                          toolBarItemsProvider: toolBarItemsProvider)
    }

    func makeAlbumListViewController() -> UIViewController? {
        let query: AlbumListQuery
        switch self.clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumListView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumListPresenter(query: query,
                                           clipCommandService: self.clipCommandService,
                                           thumbnailStorage: self.thumbnailStorage,
                                           settingStorage: self.userSettingsStorage,
                                           logger: self.logger)

        let viewController = AlbumListViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumViewController(albumId: Domain.Album.Identity) -> UIViewController? {
        let query: AlbumQuery
        switch self.clipQueryService.queryAlbum(having: albumId) {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumView for album having id \(albumId). (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumPresenter(query: query,
                                       clipCommandService: self.clipCommandService,
                                       thumbnailStorage: self.thumbnailStorage,
                                       settingStorage: self.userSettingsStorage,
                                       logger: self.logger)

        let navigationItemsPresenter = ClipsListNavigationItemsPresenter(dataSource: presenter)
        let navigationItemsProvider = ClipsListNavigationItemsProvider(presenter: navigationItemsPresenter)

        let toolBarItemsPresenter = ClipsListToolBarItemsPresenter(target: .album, dataSource: presenter)
        let toolBarItemsProvider = ClipsListToolBarItemsProvider(presenter: toolBarItemsPresenter)

        return AlbumViewController(factory: self,
                                   presenter: presenter,
                                   clipsListCollectionViewProvider: ClipsListCollectionViewProvider(),
                                   navigationItemsProvider: navigationItemsProvider,
                                   toolBarItemsProvider: toolBarItemsProvider)
    }

    func makeAlbumSelectionViewController(context: Any?, delegate: AlbumSelectionPresenterDelegate) -> UIViewController? {
        let query: AlbumListQuery
        switch self.clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open AlbumSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = AlbumSelectionPresenter(query: query,
                                                context: context,
                                                clipCommandService: self.clipCommandService,
                                                thumbnailStorage: self.thumbnailStorage,
                                                settingStorage: self.userSettingsStorage,
                                                logger: self.logger)
        presenter.delegate = delegate
        let viewController = AlbumSelectionViewController(factory: self, presenter: presenter)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagListViewController() -> UIViewController? {
        let query: TagListQuery
        switch self.clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TagListPresenter(query: query,
                                         clipCommandService: self.clipCommandService,
                                         logger: self.logger)
        let viewController = TagListViewController(factory: self, presenter: presenter, logger: self.logger)

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagSelectionViewController(selectedTags: [Domain.Tag.Identity],
                                        context: Any?,
                                        delegate: TagSelectionPresenterDelegate) -> UIViewController?
    {
        let query: TagListQuery
        switch self.clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to open TagSelectionView. (\(error.rawValue))
            """))
            return nil
        }

        let presenter = TagSelectionPresenter(query: query,
                                              selectedTags: selectedTags,
                                              context: context,
                                              clipCommandService: self.clipCommandService,
                                              logger: self.logger)
        presenter.delegate = delegate
        let viewController = TagSelectionViewController(factory: self, presenter: presenter)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController() -> UIViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.main)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let presenter = SettingsPresenter(storage: self.userSettingsStorage,
                                          container: self)
        viewController.factory = self
        viewController.presenter = presenter

        return viewController
    }
}

extension ClipCommandService: ClipStorable {}
