//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Foundation
import Persistence
import SwiftUI

final class TagStore: ObservableObject {
    @Published var tags: [Domain.Tag] = []

    private let clipQueryService: ClipQueryServiceProtocol
    private var cancellables: Set<AnyCancellable> = .init()

    init(clipQueryService: ClipQueryServiceProtocol) {
        self.clipQueryService = clipQueryService
    }

    @MainActor
    func load() {
        switch clipQueryService.queryAllTags() {
        case let .success(query):
            query.tags
                .sink { error in
                    // TODO: エラーハンドリング
                } receiveValue: { [weak self] tags in
                    self?.tags = tags
                }
                .store(in: &cancellables)

        case let .failure(error):
            // TODO: エラーハンドリング
            break
        }
    }
}
