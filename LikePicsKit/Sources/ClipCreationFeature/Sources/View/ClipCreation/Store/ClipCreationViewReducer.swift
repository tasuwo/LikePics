//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Combine
import CompositeKit
import Domain
import Environment
import Foundation

public protocol HasClipStore {
    var clipStore: ClipStorable { get }
}

public protocol HasClipRecipeFactory {
    var clipRecipeFactory: ClipRecipeFactoryProtocol { get }
}

public protocol HasImageSourceProvider {
    var imageSourceProvider: ImageSourceResolver { get }
}

public protocol HasImageLoader {
    var imageLoader: ImageLoadable { get }
}

public protocol HasUserSettingsStorage {
    var userSettingsStorage: UserSettingsStorageProtocol { get }
}

public typealias ClipCreationViewDependency = HasClipRecipeFactory
    & HasClipStore
    & HasImageLoader
    & HasImageSourceProvider
    & HasModalNotificationCenter
    & HasUserSettingsStorage

struct ClipCreationViewReducer: Reducer {
    typealias Dependency = ClipCreationViewDependency
    typealias State = ClipCreationViewState
    typealias Action = ClipCreationViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            let (nextState1, effects1) = Self.prepareQueryEffects(nextState, dependency)
            let (nextState2, effects2) = Self.loadImages(nextState1, dependency)
            return (nextState2, effects1 + effects2)

        // MARK: State Observation

        case let .imagesLoaded(sources):
            nextState.ImageSources = .init(sources, selectAll: state.source.fromLocal)
            nextState.displayState = .loaded
            return (nextState, .none)

        case .imagesSaved:
            dependency.modalNotificationCenter.post(id: state.id, name: .clipCreationModalDidFinish, userInfo: nil)
            nextState.isDismissed = true
            return (nextState, .none)

        case let .failedToLoadImages(error):
            nextState.displayState = .error(title: error.displayTitle, message: error.displayMessage)
            return (nextState, .none)

        case let .failedToSaveImages(error):
            nextState.alert = .error(title: error.displayTitle, message: error.displayMessage)
            nextState.displayState = .loaded
            return (nextState, .none)

        case let .settingsUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (Self.performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        // MARK: Control

        case .loadImages:
            return Self.loadImages(nextState, dependency)

        case .saveImages:
            guard nextState.isDoneItemEnabled else { return (nextState, .none) }
            return Self.saveImages(nextState, dependency)

        case let .editedUrl(url):
            nextState.url = url
            return (nextState, .none)

        case let .shouldSaveAsHiddenItem(shouldHide):
            nextState.shouldSaveAsHiddenItem = shouldHide
            return (nextState, .none)

        case let .shouldSaveAsClip(isOn):
            nextState.shouldSaveAsClip = isOn
            return (nextState, .none)

        case .tapTagAdditionButton:
            nextState.modal = .tagSelection(id: UUID(), tagIds: Set(state.tags.ids))
            return (nextState, .none)

        case .tapAlbumAdditionButton:
            nextState.modal = .albumSelection(id: UUID(), albumIds: Set(state.albums.ids))
            return (nextState, .none)

        case let .tapAlbumDeletionButton(albumId, _):
            nextState.albums = state.albums.removingEntity(having: albumId)
            return (nextState, .none)

        case let .tagRemoveButtonTapped(tagId):
            nextState.tags = nextState.tags.removingEntity(having: tagId)
            return (nextState, .none)

        case let .selected(id):
            guard !state.ImageSources.selections.contains(id) else { return (nextState, .none) }
            nextState.ImageSources = state.ImageSources.selected(id)
            return (nextState, .none)

        case let .deselected(id):
            guard state.ImageSources.selections.contains(id) else { return (nextState, .none) }
            nextState.ImageSources = state.ImageSources.deselected(id)
            return (nextState, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tags):
            guard let tags = tags else {
                nextState.modal = nil
                return (nextState, .none)
            }
            return (Self.performFilter(tags: tags, previousState: state), .none)

        case let .albumsSelected(albums):
            guard let albums = albums else {
                nextState.modal = nil
                return (nextState, .none)
            }
            return (Self.performFilter(albums: albums, previousState: state), .none)

        case .modalCompleted:
            nextState.modal = nil
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)

        // MARK: Dismisse

        case .didDismissedManually:
            dependency.modalNotificationCenter.post(id: state.id, name: .clipCreationModalDidFinish, userInfo: nil)
            nextState.isDismissed = true
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension ClipCreationViewReducer {
    static func prepareQueryEffects(_ state: State, _ dependency: Dependency) -> (State, [Effect<Action>]) {
        var nextState = state

        let settingsStream = dependency.userSettingsStorage.showHiddenItems
            .map { Action.settingsUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        nextState.isSomeItemsHidden = !dependency.userSettingsStorage.readShowHiddenItems()

        return (nextState, [settingsEffect])
    }
}

// MARK: - Load

extension ClipCreationViewReducer {
    static func loadImages(_ state: State, _ dependency: Dependency) -> (State, [Effect<Action>]) {
        var nextState = state

        nextState.displayState = .loading

        let stream = Deferred { dependency.imageSourceProvider.resolveSources() }
            .map { sources in sources.filter { $0.isValid } }
            .tryMap { sources -> Action? in
                guard !sources.isEmpty else { throw ImageSourceResolverError.notFound }
                return Action.imagesLoaded(sources)
            }
            .catch { error -> AnyPublisher<Action?, Never> in
                let error = (error as? ImageSourceResolverError) ?? ImageSourceResolverError.internalError
                return Just(Action.failedToLoadImages(error))
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        let effect = Effect(stream)

        return (nextState, [effect])
    }
}

private extension ImageSourceResolverError {
    var displayTitle: String {
        switch self {
        case .notFound:
            return L10n.clipCreationViewLoadingErrorNotFoundTitle

        case .networkError:
            return L10n.clipCreationViewLoadingErrorConnectionTitle

        case .internalError:
            return L10n.clipCreationViewLoadingErrorInternalTitle

        case .timeout:
            return L10n.clipCreationViewLoadingErrorTimeoutTitle
        }
    }

    var displayMessage: String {
        switch self {
        case .notFound:
            return L10n.clipCreationViewLoadingErrorNotFoundMessage

        case .networkError:
            return L10n.clipCreationViewLoadingErrorConnectionMessage

        case .internalError:
            return L10n.clipCreationViewLoadingErrorInternalMessage

        case .timeout:
            return L10n.clipCreationViewLoadingErrorTimeoutMessage
        }
    }
}

// MARK: - Filter

extension ClipCreationViewReducer {
    private static func performFilter(tags: [Tag], previousState: State) -> State {
        performFilter(tags: tags,
                      albums: previousState.albums.orderedEntities(),
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(albums: [ListingAlbumTitle], previousState: State) -> State {
        performFilter(tags: previousState.tags.orderedEntities(),
                      albums: albums,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool, previousState: State) -> State {
        performFilter(tags: previousState.tags.orderedEntities(),
                      albums: previousState.albums.orderedEntities(),
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(tags: [Tag],
                                      albums: [ListingAlbumTitle],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var nextState = previousState

        let filteredTagIds = tags
            .filter { isSomeItemsHidden ? $0.isHidden == false : true }
            .map { $0.id }
        let filteredAlbumIds = albums
            .filter { isSomeItemsHidden ? $0.isHidden == false : true }
            .map { $0.id }

        nextState.tags = nextState.tags
            .updated(entities: tags)
            .updated(filteredIds: Set(filteredTagIds))
        nextState.albums = nextState.albums
            .updated(entities: albums)
            .updated(filteredIds: Set(filteredAlbumIds))
        nextState.isSomeItemsHidden = isSomeItemsHidden

        return nextState
    }
}

// MARK: - Save

extension ClipCreationViewReducer {
    enum DownloadError: Error {
        case failedToSave(ClipStorageError)
        case failedToDownloadImage(ImageLoaderError)
        case failedToCreateClipItemSource(ClipItemPartialRecipe.InitializeError)
        case internalError
    }

    static func saveImages(_ state: State, _ dependency: Dependency) -> (State, [Effect<Action>]) {
        var nextState = state

        nextState.displayState = .saving

        let selections = state.ImageSources.selections
            .compactMap { state.ImageSources.ImageSourceById[$0] }
            .enumerated()
            .reduce(into: [(Int, ImageSource)]()) { $0.append(($1.offset, $1.element)) }

        let stream = self.fetchImages(for: selections, dependency: dependency)
            .flatMap { [dependency] partialRecipes -> AnyPublisher<Action?, DownloadError> in
                return Self.save(url: state.url,
                                 shouldSaveAsClip: state.shouldSaveAsClip,
                                 shouldSaveAsHiddenItem: state.shouldSaveAsHiddenItem,
                                 tagIds: Array(state.tags.ids),
                                 albumIds: state.albums.ids,
                                 partialRecipes: partialRecipes,
                                 dependency: dependency)
                    .publisher
                    .eraseToAnyPublisher()
            }
            .catch { error -> AnyPublisher<Action?, Never> in
                return Just(Action.failedToSaveImages(error))
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        let effect = Effect(stream)

        return (nextState, [effect])
    }

    private static func fetchImages(for selections: [(index: Int, source: ImageSource)], dependency: Dependency) -> AnyPublisher<[ClipItemPartialRecipe], DownloadError> {
        let publishers: [AnyPublisher<ClipItemPartialRecipe, DownloadError>] = selections
            .map { [dependency] selection in
                return dependency.imageLoader.load(from: selection.source)
                    .mapError { DownloadError.failedToDownloadImage($0) }
                    .tryMap { try ClipItemPartialRecipe(index: selection.index, result: $0) }
                    .mapError { err in
                        if let error = err as? DownloadError {
                            return error
                        } else if let error = err as? ClipItemPartialRecipe.InitializeError {
                            return DownloadError.failedToCreateClipItemSource(error)
                        } else {
                            return DownloadError.internalError
                        }
                    }
                    .eraseToAnyPublisher()
            }
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }

    // swiftlint:disable:next function_parameter_count
    private static func save(url: URL?,
                             shouldSaveAsClip: Bool,
                             shouldSaveAsHiddenItem: Bool,
                             tagIds: [Tag.Identity],
                             albumIds: Set<Album.Identity>,
                             partialRecipes: [ClipItemPartialRecipe],
                             dependency: Dependency) -> Result<Action?, DownloadError>
    {
        if shouldSaveAsClip {
            let result = dependency.clipRecipeFactory.make(url: url,
                                                           hidesClip: shouldSaveAsHiddenItem,
                                                           partialRecipes: partialRecipes,
                                                           tagIds: tagIds,
                                                           albumIds: albumIds)
            switch dependency.clipStore.create(clip: result.0, withContainers: result.1, forced: false) {
            case .success:
                return .success(.imagesSaved)

            case let .failure(error):
                return .failure(.failedToSave(error))
            }
        } else {
            var results: [Result<Clip.Identity, ClipStorageError>] = []
            for partialRecipe in partialRecipes {
                let result = dependency.clipRecipeFactory.make(url: url,
                                                               hidesClip: shouldSaveAsHiddenItem,
                                                               partialRecipes: [partialRecipe],
                                                               tagIds: tagIds,
                                                               albumIds: albumIds)
                results.append(dependency.clipStore.create(clip: result.0, withContainers: result.1, forced: false))
            }
            if let firstError = results.compactMap({ $0.failureValue }).first {
                return .failure(.failedToSave(firstError))
            } else {
                return .success(.imagesSaved)
            }
        }
    }
}

private extension ClipCreationViewReducer.DownloadError {
    var displayTitle: String {
        switch self {
        case .failedToDownloadImage:
            return L10n.clipCreationViewDownloadErrorFailedToDownloadTitle

        default:
            return L10n.clipCreationViewDownloadErrorFailedToSaveTitle
        }
    }

    var displayMessage: String {
        switch self {
        case .failedToDownloadImage:
            return L10n.clipCreationViewDownloadErrorFailedToDownloadBody

        default:
            return L10n.clipCreationViewDownloadErrorFailedToSaveBody
        }
    }
}
