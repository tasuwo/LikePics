//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit

public protocol HasClipStore {
    var clipStore: ClipStorable { get }
}

public protocol HasClipBuilder {
    var clipBuilder: ClipBuildable { get }
}

public protocol HasImageSourceProvider {
    var imageSourceProvider: ImageSourceProvider { get }
}

public protocol HasImageLoader {
    var imageLoader: ImageLoaderProtocol { get }
}

public protocol HasUserSettingsStorage {
    var userSettingsStorage: UserSettingsStorageProtocol { get }
}

public typealias ClipCreationViewDependency = HasClipStore
    & HasClipBuilder
    & HasImageSourceProvider
    & HasImageLoader
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

        case let .imagesLoaded(imageSources):
            nextState.imageSources = .init(imageSources)
            nextState.displayState = .loaded

            // TODO: 必要であれば選択する
            return (nextState, .none)

        case let .failedToLoadImages(error):
            nextState.displayState = .error(title: error.displayTitle, message: error.displayMessage)
            return (nextState, .none)

        case let .settingsUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (Self.performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        // MARK: Control

        case .loadImages:
            return Self.loadImages(nextState, dependency)

        case .saveImages:
            // TODO:
            return (nextState, .none)

        case let .editedUrl(url):
            nextState.url = url
            return (nextState, .none)

        case let .shouldSaveAsHiddenItem(shouldHide):
            nextState.shouldSaveAsHiddenItem = shouldHide
            return (nextState, .none)

        case let .tagRemoveButtonTapped(tagId):
            nextState.tags = nextState.tags.removingEntity(having: tagId)
            return (nextState, .none)

        case let .selected(id):
            nextState.imageSources = state.imageSources.selected(id)
            return (nextState, .none)

        case let .deselected(id):
            nextState.imageSources = state.imageSources.deselected(id)
            return (nextState, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tags):
            guard let tags = tags else {
                nextState.modal = nil
                return (nextState, .none)
            }
            return (Self.performFilter(tags: tags, previousState: state), .none)

        case .modalCompleted:
            nextState.modal = nil
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
                guard !sources.isEmpty else { throw ImageSourceProviderError.notFound }
                return Action.imagesLoaded(sources)
            }
            .catch { error -> AnyPublisher<Action?, Never> in
                let error = (error as? ImageSourceProviderError) ?? ImageSourceProviderError.internalError
                return Just(Action.failedToLoadImages(error))
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        let effect = Effect(stream)

        return (nextState, [effect])
    }
}

// MARK: - Filter

extension ClipCreationViewReducer {
    private static func performFilter(tags: [Tag], previousState: State) -> State {
        performFilter(tags: tags,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool, previousState: State) -> State {
        performFilter(tags: previousState.tags.orderedEntities(),
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(tags: [Tag],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var nextState = previousState

        let filteredTagIds = tags
            .filter { isSomeItemsHidden ? $0.isHidden == false : true }
            .map { $0.id }

        nextState.tags = nextState.tags
            .updated(entities: tags.indexed())
            .updated(filteredIds: Set(filteredTagIds))
        nextState.isSomeItemsHidden = isSomeItemsHidden

        return nextState
    }
}
