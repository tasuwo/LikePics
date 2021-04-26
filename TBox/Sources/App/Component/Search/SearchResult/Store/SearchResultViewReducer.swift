//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

typealias SearchResultViewDependency = HasClipQueryService

enum SearchResultViewReducer: Reducer {
    typealias Dependency = SearchResultViewDependency
    typealias State = SearchResultViewState
    typealias Action = SearchResultViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        case let .searchQueryChanged(query):
            nextState.searchQuery = query
            nextState.tokenCandidates = searchCandidates(for: query, dependency: dependency)

        case let .selectedTokenCandidate(token):
            nextState.searchQuery = state.searchQuery.appending(token: token)

        case .selectedResult(_):
            // TODO:
            break

        case .selectedSeeAllResultsButton:
            // TODO:
            break
        }
        return (nextState, nil)
    }
}

// MARK: - Candidates

extension SearchResultViewReducer {
    private static func searchCandidates(for query: SearchQuery, dependency: Dependency) -> [SearchToken] {
        // TODO: パフォーマンス向上
        let albumTokens = self.searchAlbumCandidates(for: query, dependency: dependency)
            .map { SearchToken(kind: .album, id: $0.id, title: $0.title) }
        let tagTokens = self.searchTagCandidates(for: query, dependency: dependency)
            .map { SearchToken(kind: .tag, id: $0.id, title: $0.name) }
        return tagTokens + albumTokens
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
