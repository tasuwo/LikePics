//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias TagCollectionViewDependency = HasClipCommandService
    & HasRouter
    & HasPasteboard
    & HasClipQueryService
    & HasUserSettingStorage

enum TagCollectionViewReducer: Reducer {
    typealias Dependency = TagCollectionViewDependency
    typealias State = TagCollectionViewState
    typealias Action = TagCollectionViewAction

    typealias Layout = TagCollectionViewLayout

    // MARK: - Methods

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return prepareQueryEffects(state, dependency)

        // MARK: State Observation

        case let .tagsUpdated(tags):
            return (performFilter(by: tags, previousState: state), .none)

        case let .searchQueryChanged(query):
            return (performFilter(bySearchQuery: query, previousState: state), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(byItemsVisibility: isSomeItemsHidden, previousState: state), .none)

        // MARK: Selection

        case let .select(tag):
            dependency.router.showClipCollectionView(for: tag)
            return (state, .none)

        case let .hide(tag):
            switch dependency.clipCommandService.updateTag(having: tag.id, byHiding: true) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.errorTagDefault)
            }
            return (nextState, .none)

        // MARK: Button Action

        case .emptyMessageViewActionButtonTapped, .tagAdditionButtonTapped:
            nextState.alert = .addition
            return (nextState, .none)

        case .uncategorizedTagButtonTapped:
            dependency.router.showUncategorizedClipCollectionView()
            return (state, .none)

        // MARK: Context Menu

        case let .copyMenuSelected(tag):
            dependency.pasteboard.set(tag.name)
            return (state, .none)

        case let .hideMenuSelected(tag):
            if state.isSomeItemsHidden {
                let stream = Deferred {
                    Future<Action?, Never> { promise in
                        // HACK: アイテム削除とContextMenuのドロップのアニメーションがコンフリクトするため、
                        //       アイテム削除を遅延させて自然なアニメーションにする
                        //       https://stackoverflow.com/a/57997005
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            promise(.success(.hide(tag)))
                        }
                    }
                }
                return (state, [Effect(stream)])
            } else {
                return (state, [Effect(value: .hide(tag))])
            }

        case let .revealMenuSelected(tag):
            switch dependency.clipCommandService.updateTag(having: tag.id, byHiding: false) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.errorTagDefault)
            }
            return (nextState, .none)

        case let .deleteMenuSelected(tag):
            nextState.alert = .deletion(tagId: tag.id, tagName: tag.name)
            return (nextState, .none)

        case let .renameMenuSelected(tag):
            nextState.alert = .edit(tagId: tag.id, name: tag.name)
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDeleteConfirmTapped:
            switch state.alert {
            case let .deletion(tagId: tagId, tagName: _):
                switch dependency.clipCommandService.deleteTags(having: [tagId]) {
                case .success:
                    nextState.alert = nil

                case .failure:
                    nextState.alert = .error(L10n.errorTagDelete)
                }

            default:
                nextState.alert = nil
            }
            return (nextState, .none)

        case let .alertSaveButtonTapped(text: text):
            switch state.alert {
            case .addition:
                switch dependency.clipCommandService.create(tagWithName: text) {
                case .success:
                    nextState.alert = nil

                case .failure(.duplicated):
                    nextState.alert = .error(L10n.errorTagRenameDuplicated)

                case .failure:
                    nextState.alert = .error(L10n.errorTagDefault)
                }

            case let .edit(tagId: tagId, name: _):
                switch dependency.clipCommandService.updateTag(having: tagId, nameTo: text) {
                case .success:
                    nextState.alert = nil

                case .failure(.duplicated):
                    nextState.alert = .error(L10n.errorTagRenameDuplicated)

                case .failure:
                    nextState.alert = .error(L10n.errorTagDefault)
                }

            default:
                nextState.alert = nil
            }
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

extension TagCollectionViewReducer {
    private static func prepareQueryEffects(_ state: State, _ dependency: Dependency) -> (State, [Effect<Action>]) {
        let query: TagListQuery
        switch dependency.clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            fatalError("Failed to load tags: \(error.localizedDescription)")
        }

        let tagsStream = query.tags
            .catch { _ in Just([]) }
            .map { Action.tagsUpdated($0) as Action? }
        let tagsEffect = Effect(tagsStream, underlying: query)

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        let nextState = performFilter(tags: query.tags.value,
                                      searchQuery: state.searchQuery,
                                      isSomeItemsHidden: !dependency.userSettingStorage.readShowHiddenItems(),
                                      previousState: state)

        return (nextState, [tagsEffect, settingsEffect])
    }
}

// MARK: Filter

extension TagCollectionViewReducer {
    private static func performFilter(by tags: [Tag], previousState: State) -> State {
        return performFilter(tags: tags,
                             searchQuery: previousState.searchQuery,
                             isSomeItemsHidden: previousState.isSomeItemsHidden,
                             previousState: previousState)
    }

    private static func performFilter(bySearchQuery searchQuery: String, previousState: State) -> State {
        return performFilter(tags: previousState.tags.orderedValues(),
                             searchQuery: searchQuery,
                             isSomeItemsHidden: previousState.isSomeItemsHidden,
                             previousState: previousState)
    }

    private static func performFilter(byItemsVisibility isSomeItemsHidden: Bool, previousState: State) -> State {
        return performFilter(tags: previousState.tags.orderedValues(),
                             searchQuery: previousState.searchQuery,
                             isSomeItemsHidden: isSomeItemsHidden,
                             previousState: previousState)
    }

    private static func performFilter(tags: [Tag],
                                      searchQuery: String,
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var nextState = previousState
        var searchStorage = previousState.searchStorage

        let filteringTags = tags.filter { isSomeItemsHidden ? $0.isHidden == false : true }
        let filteredTagIds = searchStorage.perform(query: searchQuery, to: filteringTags).map { $0.id }

        let newTags = previousState.tags
            .updated(values: tags.indexed())
            .updated(filteredIds: Set(filteredTagIds))
        nextState.tags = newTags

        nextState.searchQuery = searchQuery
        nextState.isSomeItemsHidden = isSomeItemsHidden
        nextState.searchStorage = searchStorage

        if filteringTags.isEmpty, !searchQuery.isEmpty {
            nextState.searchQuery = ""
        }

        nextState.isCollectionViewHidden = filteringTags.isEmpty
        nextState.isEmptyMessageViewHidden = !filteringTags.isEmpty
        nextState.isSearchBarEnabled = !filteringTags.isEmpty

        return nextState
    }
}
