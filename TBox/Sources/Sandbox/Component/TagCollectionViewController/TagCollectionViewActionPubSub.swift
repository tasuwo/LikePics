//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

class TagCollectionViewActionPubSub {
    private weak var tagCollectionViewStore: Store<TagCollectionViewState, TagCollectionViewAction, TagCollectionViewDependency>?
    private weak var tagEditAlertStore: Store<TextEditAlertState, TextEditAlertAction, TextEditAlertDependency>?
    private weak var tagAdditionAlertStore: Store<TextEditAlertState, TextEditAlertAction, TextEditAlertDependency>?

    init(tagCollectionViewStore: Store<TagCollectionViewState, TagCollectionViewAction, TagCollectionViewDependency>,
         tagEditAlertStore: Store<TextEditAlertState, TextEditAlertAction, TextEditAlertDependency>,
         tagAdditionAlertStore: Store<TextEditAlertState, TextEditAlertAction, TextEditAlertDependency>)
    {
        self.tagCollectionViewStore = tagCollectionViewStore
        self.tagEditAlertStore = tagEditAlertStore
        self.tagAdditionAlertStore = tagAdditionAlertStore

        tagCollectionViewStore.publisher = self
        tagEditAlertStore.publisher = self
        tagAdditionAlertStore.publisher = self
    }
}

extension TagCollectionViewActionPubSub: ActionPublisher {
    // MARK: - ActionPublisher

    func publish(_ action: Action, for store: AnyObject) {
        if let action = action as? TextEditAlertAction {
            handle(action, for: store)
        }
    }

    private func handle(_ action: TextEditAlertAction, for store: AnyObject) {
        switch action {
        case let .completed(withText: text):
            tagCollectionViewStore?.execute(.alertSaveButtonTapped(text: text))

        case .cancelActionTapped, .dismissed:
            tagCollectionViewStore?.execute(.alertDismissed)

        default:
            break
        }
    }
}
