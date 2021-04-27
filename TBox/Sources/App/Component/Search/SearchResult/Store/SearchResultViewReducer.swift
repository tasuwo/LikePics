//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Foundation

typealias SearchResultViewDependency = HasClipQueryService
    & HasRouter

enum SearchResultViewReducer: Reducer {
    typealias Dependency = SearchResultViewDependency
    typealias State = SearchResultViewState
    typealias Action = SearchResultViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: - State Observation

        case let .searchQueryChanged(query):
            nextState.searchQuery = query
            let searchCandidateEffect = searchCandidates(for: query, dependency: dependency)
                .debounce(id: state.searchCandidatesEffectId, for: 0.01, scheduler: DispatchQueue.main)
            let searchEffect = search(by: query, dependency: dependency)
                .debounce(id: state.searchEffectId, for: 0.15, scheduler: DispatchQueue.main)
            return (nextState, [searchCandidateEffect, searchEffect])

        // MARK: - Selection

        case let .selectedTokenCandidate(token):
            nextState.searchQuery = state.searchQuery.appending(token: token)
            return (nextState, nil)

        case let .selectedResult(clip):
            dependency.router.showClipPreviewView(for: clip.id)
            return (nextState, nil)

        case .selectedSeeAllResultsButton:
            // TODO:
            return (nextState, nil)

        // MARK: - Search Execution

        case let .foundResults(clips):
            nextState.searchResults = clips
            return (nextState, nil)

        case let .foundCandidates(tokens):
            nextState.tokenCandidates = tokens
            return (nextState, nil)
        }
    }
}

// MARK: - Search

extension SearchResultViewReducer {
    private static func search(by query: SearchQuery, dependency: Dependency) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let albumIds = query.tokens
                    .filter { $0.kind == .album }
                    .map { $0.id }
                let tagIds = query.tokens
                    .filter { $0.kind == .tag }
                    .map { $0.id }
                switch dependency.clipQueryService.searchClips(text: query.text, albumIds: albumIds, tagIds: tagIds) {
                case let .success(clips):
                    promise(.success(.foundResults(clips)))

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
    private static func searchCandidates(for query: SearchQuery, dependency: Dependency) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let albumTokens = self.searchAlbumCandidates(for: query, dependency: dependency)
                    .map { SearchToken(kind: .album, id: $0.id, title: $0.title) }
                let tagTokens = self.searchTagCandidates(for: query, dependency: dependency)
                    .map { SearchToken(kind: .tag, id: $0.id, title: $0.name) }
                promise(.success(.foundCandidates(tagTokens + albumTokens)))
            }
        }
        return Effect(stream)
    }

    private static func searchAlbumCandidates(for query: SearchQuery, dependency: Dependency) -> [Album] {
        switch dependency.clipQueryService.searchAlbums(containingTitle: query.text, limit: 6) {
        case let .success(albums):
            return albums

        case .failure:
            return []
        }
    }

    private static func searchTagCandidates(for query: SearchQuery, dependency: Dependency) -> [Tag] {
        switch dependency.clipQueryService.searchTags(containingName: query.text, limit: 6) {
        case let .success(tags):
            return tags

        case .failure:
            return []
        }
    }
}
