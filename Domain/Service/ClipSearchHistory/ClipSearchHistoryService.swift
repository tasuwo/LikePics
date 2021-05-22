//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol ClipSearchHistoryService {
    func append(_ history: ClipSearchHistory)
    func remove(historyHaving id: UUID)
    func removeAll()
    func read() -> [ClipSearchHistory]
    func query() -> AnyPublisher<[ClipSearchHistory], Never>
}
