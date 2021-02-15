//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum TextEditAlertAction {
    case presented
    case textChanged(text: String)
    case saveActionTapped
    case cancelActionTapped
    case dismissed
}

extension TextEditAlertAction: Action {}
