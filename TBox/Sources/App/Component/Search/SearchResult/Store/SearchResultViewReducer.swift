//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Foundation

typealias SearchResultViewDependency = HasClipQueryService
    & HasRouter
    & HasUserSettingStorage

enum SearchResultViewReducer: Reducer {
    typealias Dependency = SearchResultViewDependency
    typealias State = SearchResultViewState
    typealias Action = SearchResultViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        let resolveSearchEffects: () -> [Effect<Action>] = {
            var effects: [Effect<Action>] = []

            if nextState.inputtedText != state.searchedTokenCandidates?.searchText
                || !nextState.isSomeItemsHidden != state.searchedTokenCandidates?.includesHiddenItems
            {
                let effect = searchCandidates(for: nextState.inputtedText, includesHiddenItems: !state.isSomeItemsHidden, dependency: dependency)
                    .debounce(id: state.searchCandidatesEffectId, for: 0.01, scheduler: DispatchQueue.main)
                nextState.isSearchingTokenCandidates = true
                effects.append(effect)
            }

            if nextState.searchQuery != state.searchedClips?.searchQuery {
                let effect = search(query: nextState.searchQuery, dependency: dependency)
                    .debounce(id: state.searchEffectId, for: 0.15, scheduler: DispatchQueue.main)
                nextState.isSearchingClips = true
                effects.append(effect)
            }

            return effects
        }

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return prepare(state, dependency)

        // MARK: - State Observation

        case let .searchBarChanged(text: text, tokens: tokens):
            nextState.inputtedText = text
            nextState.inputtedTokens = tokens
            return (nextState, resolveSearchEffects())

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            nextState.isSomeItemsHidden = isSomeItemsHidden
            return (nextState, resolveSearchEffects())

        // MARK: - Menu

        case let .displaySettingMenuChanged(searchOnlyHiddenItems):
            nextState.searchOnlyHiddenItems = searchOnlyHiddenItems
            return (nextState, resolveSearchEffects())

        case let .sortMenuChanged(sort):
            nextState.selectedSort = sort
            return (nextState, resolveSearchEffects())

        // MARK: - Selection

        case let .selectedTokenCandidate(token):
            nextState.inputtedTokens = state.inputtedTokens + [token]
            return (nextState, nil)

        case let .selectedResult(clip):
            dependency.router.showClipPreviewView(for: clip.id)
            return (nextState, nil)

        case .selectedSeeAllResultsButton:
            dependency.router.showClipCollectionView(for: state.searchQuery, with: state.searchQueryTitle)
            return (nextState, nil)

        // MARK: - Search Execution

        case let .foundResults(clips, byQuery: query):
            nextState.searchedClips = .init(searchQuery: query, results: clips)
            nextState.isSearchingClips = false
            return (nextState, nil)

        case let .foundCandidates(tokens, byText: text, includesHiddenItems: includesHiddenItems):
            nextState.searchedTokenCandidates = .init(searchText: text, includesHiddenItems: includesHiddenItems, tokenCandidates: tokens)
            nextState.isSearchingTokenCandidates = false
            return (nextState, nil)
        }
    }
}

// MARK: - Preparation

extension SearchResultViewReducer {
    private static func prepare(_ state: State, _ dependency: Dependency) -> (State, [Effect<Action>]) {
        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)
        return (state, [settingsEffect])
    }
}

// MARK: - Search

extension SearchResultViewReducer {
    private static func search(query: ClipSearchQuery, dependency: Dependency) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                switch dependency.clipQueryService.searchClips(query: query) {
                case let .success(clips):
                    promise(.success(.foundResults(clips, byQuery: query)))

                case .failure:
                    promise(.success(nil))
                }
            }
        }
        return Effect(stream)
    }
}

// MARK: - Candidates

extension SearchResultViewReducer {
    private static func searchCandidates(for text: String, includesHiddenItems: Bool, dependency: Dependency) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let albumTokens = self.searchAlbumCandidates(for: text, includesHiddenItems: includesHiddenItems, dependency: dependency)
                    .map { SearchToken(kind: .album, id: $0.id, title: $0.title) }
                let tagTokens = self.searchTagCandidates(for: text, includesHiddenItems: includesHiddenItems, dependency: dependency)
                    .map { SearchToken(kind: .tag, id: $0.id, title: $0.name) }
                promise(.success(.foundCandidates(tagTokens + albumTokens, byText: text, includesHiddenItems: includesHiddenItems)))
            }
        }
        return Effect(stream)
    }

    private static func searchAlbumCandidates(for text: String, includesHiddenItems: Bool, dependency: Dependency) -> [Album] {
        switch dependency.clipQueryService.searchAlbums(containingTitle: text, includesHiddenItems: includesHiddenItems, limit: 6) {
        case let .success(albums):
            return albums

        case .failure:
            return []
        }
    }

    private static func searchTagCandidates(for text: String, includesHiddenItems: Bool, dependency: Dependency) -> [Tag] {
        switch dependency.clipQueryService.searchTags(containingName: text, includesHiddenItems: includesHiddenItems, limit: 6) {
        case let .success(tags):
            return tags

        case .failure:
            return []
        }
    }
}
