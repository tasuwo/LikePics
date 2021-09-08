//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import Foundation

typealias SearchResultViewDependency = HasClipQueryService
    & HasRouter
    & HasUserSettingStorage
    & HasClipSearchSettingService
    & HasClipSearchHistoryService

struct SearchResultViewReducer: Reducer {
    typealias Dependency = SearchResultViewDependency
    typealias State = SearchResultViewState
    typealias Action = SearchResultViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return Self.prepare(state, dependency)

        case .entryViewDidAppear:
            // 別画面で状態が更新されている可能性があるため、再建策をかける
            let effects = Self.resolveSearchEffects(nextState: &nextState, prevState: state, dependency: dependency, forced: true)
            return (nextState, effects)

        // MARK: - State Observation

        case let .searchBarChanged(text: text, tokens: tokens):
            nextState.inputtedText = text
            nextState.inputtedTokens = tokens
            let effects = Self.resolveSearchEffects(nextState: &nextState, prevState: state, dependency: dependency)
            return (nextState, effects)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            nextState.isSomeItemsHidden = isSomeItemsHidden
            let effects = Self.resolveSearchEffects(nextState: &nextState, prevState: state, dependency: dependency)
            return (nextState, effects)

        // MARK: - Menu

        case let .displaySettingMenuChanged(searchOnlyHiddenItems):
            nextState.searchOnlyHiddenItems = searchOnlyHiddenItems
            dependency.clipSearchSettingService.save(.init(isHidden: searchOnlyHiddenItems, sort: state.selectedSort))
            let effects = Self.resolveSearchEffects(nextState: &nextState, prevState: state, dependency: dependency)
            return (nextState, effects)

        case let .sortMenuChanged(sort):
            nextState.selectedSort = sort
            dependency.clipSearchSettingService.save(.init(isHidden: state.searchOnlyHiddenItems, sort: sort))
            let effects = Self.resolveSearchEffects(nextState: &nextState, prevState: state, dependency: dependency)
            return (nextState, effects)

        // MARK: - Selection

        case let .selectedHistory(history):
            nextState.inputtedText = history.query.text
            nextState.inputtedTokens = history.query.tokens
            nextState.selectedSort = history.query.sort
            nextState.searchOnlyHiddenItems = history.query.isHidden
            let effects = Self.resolveSearchEffects(nextState: &nextState, prevState: state, dependency: dependency)
            return (nextState, effects)

        case let .selectedTokenCandidate(token):
            nextState.inputtedText = state.inputtedText.removingTokenCandidatesSource()
            nextState.inputtedTokens = state.inputtedTokens + [token]
            return (nextState, nil)

        case let .selectedResult(clip):
            // TODO: 選択を反映する
            dependency.router.showClipPreviewView(clips: .init(), source: .search(state.searchQuery), indexPath: nil)
            return (nextState, nil)

        case .selectedSeeAllResultsButton:
            dependency.clipSearchHistoryService.append(.init(id: UUID(), query: state.searchQuery, date: Date()))
            dependency.router.showClipCollectionView(for: state.searchQuery)
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
        var nextState = state

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        let savedSetting = dependency.clipSearchSettingService.read() ?? .default
        nextState.searchOnlyHiddenItems = savedSetting.isHidden
        nextState.selectedSort = savedSetting.sort

        return (nextState, [settingsEffect])
    }
}

// MARK: - Search

// MARK: Resolve Effects

extension SearchResultViewReducer {
    private static func resolveSearchEffects(nextState: inout State, prevState: State, dependency: Dependency, forced: Bool = false) -> [Effect<Action>] {
        var effects: [Effect<Action>] = []

        if forced ||
            (nextState.inputtedText != prevState.searchedTokenCandidates?.searchText
                || !nextState.isSomeItemsHidden != prevState.searchedTokenCandidates?.includesHiddenItems)
        {
            let effect = searchCandidates(for: nextState.inputtedText, includesHiddenItems: !prevState.isSomeItemsHidden, dependency: dependency)
                .debounce(id: prevState.searchCandidatesEffectId, for: 0.01, scheduler: DispatchQueue.main)
            nextState.isSearchingTokenCandidates = true
            effects.append(effect)
        }

        if forced || nextState.searchQuery != prevState.searchedClips?.searchQuery {
            let effect = search(query: nextState.searchQuery, dependency: dependency)
                .debounce(id: prevState.searchEffectId, for: 0.15, scheduler: DispatchQueue.main)
            nextState.isSearchingClips = true
            effects.append(effect)
        }

        return effects
    }
}

// MARK: Clips

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

// MARK: Candidates

extension SearchResultViewReducer {
    private static func searchCandidates(for text: String, includesHiddenItems: Bool, dependency: Dependency) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let albumTokens = self.searchAlbumCandidates(for: text.tokenCandidatesSource, includesHiddenItems: includesHiddenItems, dependency: dependency)
                    .map { ClipSearchToken(kind: .album, id: $0.id, title: $0.title) }
                let tagTokens = self.searchTagCandidates(for: text.tokenCandidatesSource, includesHiddenItems: includesHiddenItems, dependency: dependency)
                    .map { ClipSearchToken(kind: .tag, id: $0.id, title: $0.name) }
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

// MARK: Extension

private extension String {
    var tokenCandidatesSource: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").last.map { String($0) } ?? self
    }

    func removingTokenCandidatesSource() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").dropLast().joined(separator: " ")
    }
}
