//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

public class ClipSearchHistoryService {
    public static let maxCount = 100

    enum Key: String {
        case histories = "clipSearchHistories"
    }

    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.ClipSearchHistoryService")

    // MARK: - Initializers

    public init() {}

    // MARK: - Methods

    private func setHistoriesNonAtomically(_ histories: [ClipSearchHistory]) {
        guard fetchHistoriesNonAtomically() != histories else { return }
        let data = histories.compactMap { try? JSONEncoder().encode($0) }
        userDefaults.set(data, forKey: Key.histories.rawValue)
    }

    private func fetchHistoriesNonAtomically() -> [ClipSearchHistory] {
        userDefaults.clipSearchHistories
            .compactMap { try? JSONDecoder().decode(ClipSearchHistory.self, from: $0) }
    }

    private func removeHistoriesNonAtomically() {
        userDefaults.removeObject(forKey: Key.histories.rawValue)
    }
}

extension UserDefaults {
    @objc dynamic var clipSearchHistories: [Data] {
        return self.array(forKey: ClipSearchHistoryService.Key.histories.rawValue) as? [Data] ?? []
    }
}

extension ClipSearchHistoryService: Domain.ClipSearchHistoryService {
    // MARK: - Domain.ClipSearchHistoryService

    public func append(_ history: ClipSearchHistory) {
        queue.async {
            var histories = self.fetchHistoriesNonAtomically()

            if let index = histories.firstIndex(where: { $0.query == history.query }) {
                histories.remove(at: index)
                histories.insert(history, at: 0)
            } else {
                histories.insert(history, at: 0)
            }

            if histories.count > Self.maxCount {
                histories.removeLast()
            }

            self.setHistoriesNonAtomically(histories)
        }
    }

    public func remove(historyHaving id: UUID) {
        queue.async {
            var histories = self.fetchHistoriesNonAtomically()
            guard let index = histories.firstIndex(where: { $0.id == id }) else { return }
            histories.remove(at: index)
            self.setHistoriesNonAtomically(histories)
        }
    }

    public func removeAll() {
        queue.async {
            self.removeHistoriesNonAtomically()
        }
    }

    public func read() -> [ClipSearchHistory] {
        return queue.sync {
            userDefaults
                .clipSearchHistories
                .compactMap { try? JSONDecoder().decode(ClipSearchHistory.self, from: $0) }
        }
    }

    public func query() -> AnyPublisher<[ClipSearchHistory], Never> {
        userDefaults
            .publisher(for: \.clipSearchHistories)
            .map { $0.compactMap { try? JSONDecoder().decode(ClipSearchHistory.self, from: $0) } }
            .eraseToAnyPublisher()
    }
}
