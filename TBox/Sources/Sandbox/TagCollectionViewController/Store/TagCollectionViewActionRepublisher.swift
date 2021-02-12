//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

class TagCollectionViewActionRepublisher {
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

        tagCollectionViewStore.republisher = self
        tagEditAlertStore.republisher = self
        tagAdditionAlertStore.republisher = self
    }
}

extension TagCollectionViewActionRepublisher: ActionRepublisher {
    // MARK: - ActionRepublisher

    func republishIfNeeded(_ action: Action, for store: AnyObject) -> Bool {
        if let action = action as? TextEditAlertAction, case .saveActionTapped = action, store === tagEditAlertStore {
            switch action {
            case .saveActionTapped:
                tagCollectionViewStore?.execute(.alertSaveButtonTapped(text: tagEditAlertStore?.stateValue.text ?? ""))
                return true

            case .cancelActionTapped, .dismissed:
                tagCollectionViewStore?.execute(.alertDismissed)
                return true

            default:
                break
            }
        }

        if let action = action as? TextEditAlertAction, case .saveActionTapped = action, store === tagAdditionAlertStore {
            switch action {
            case .saveActionTapped:
                tagCollectionViewStore?.execute(.alertSaveButtonTapped(text: tagAdditionAlertStore?.stateValue.text ?? ""))
                return true

            case .cancelActionTapped, .dismissed:
                tagCollectionViewStore?.execute(.alertDismissed)
                return true

            default:
                break
            }
        }

        return false
    }
}
