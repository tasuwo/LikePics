//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Foundation
import Persistence
import SwiftUI

final class AlbumStore: ObservableObject {
    @Published var albums: [Domain.Album] = []

    private let clipQueryService: ClipQueryServiceProtocol
    private var cancellables: Set<AnyCancellable> = .init()

    init(clipQueryService: ClipQueryServiceProtocol) {
        self.clipQueryService = clipQueryService
    }

    @MainActor
    func load() {
        switch clipQueryService.queryAllAlbums() {
        case let .success(query):
            query.albums
                .sink { error in
                    // TODO: エラーハンドリング
                } receiveValue: { [weak self] albums in
                    self?.albums = albums
                }
                .store(in: &cancellables)

        case let .failure(error):
            // TODO: エラーハンドリング
            break
        }
    }
}

extension AlbumStore: ReorderableItemStore {
    var reorderableItems: [Domain.Album] { albums }
    var reorderableItemsPublisher: AnyPublisher<[Domain.Album], Never> { $albums.eraseToAnyPublisher() }

    func apply(reorderedItems: [Domain.Album]) {
        // TODO: 実装する
    }
}
