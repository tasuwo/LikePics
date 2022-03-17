//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import LikePicsCore

class ClipsIntegrityValidator {
    typealias Store = CompositeKit.Store<ClipsIntegrityValidatorState, ClipsIntegrityValidatorAction, ClipsIntegrityValidatorDependency>

    // MARK: - Properties

    // MARK: Store

    private var store: Store

    // MARK: - Initializers

    init(dependency: ClipsIntegrityValidatorDependency) {
        self.store = .init(initialState: ClipsIntegrityValidatorState(),
                           dependency: dependency,
                           reducer: ClipsIntegrityValidatorReducer())

        DarwinNotificationCenter.default.addObserver(self, for: .shareExtensionDidCompleteRequest) { [weak self] _ in
            self?.store.execute(.shareExtensionDidCompleteRequest)
        }
        self.store.execute(.didLaunchApp)
    }
}
