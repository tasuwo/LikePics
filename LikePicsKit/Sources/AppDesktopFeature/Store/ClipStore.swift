//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Foundation
import Persistence
import SwiftUI

final class ClipStore: ObservableObject {
    @Published var clips: [Domain.Clip] = []

    private let clipQueryService: ClipQueryServiceProtocol
    private var cancellables: Set<AnyCancellable> = .init()

    init(clipQueryService: ClipQueryServiceProtocol) {
        self.clipQueryService = clipQueryService
    }

    @MainActor
    func load() {
        switch clipQueryService.queryAllClips() {
        case let .success(query):
            query.clips
                .sink { error in
                    // TODO: エラーハンドリング
                } receiveValue: { [weak self] clips in
                    self?.clips = clips
                }
                .store(in: &cancellables)

        case let .failure(error):
            // TODO: エラーハンドリング
            break
        }
    }
}
