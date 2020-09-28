//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

class SettingsPresenter {
    private let storage: UserSettingsStorageProtocol
    private var cancellableBag: Set<AnyCancellable> = .init()

    private(set) var shouldShowHiddenItems: CurrentValueSubject<Bool, Never>

    // MARK: - Lifecycle

    init(storage: UserSettingsStorageProtocol) {
        self.storage = storage
        self.shouldShowHiddenItems = .init(false)

        self.storage.showHiddenItems
            .sink(receiveValue: { [weak self] value in
                self?.shouldShowHiddenItems.send(value)
            })
            .store(in: &self.cancellableBag)
    }

    func set(showHiddenItems: Bool) {
        self.storage.set(showHiddenItems: showHiddenItems)
    }
}
