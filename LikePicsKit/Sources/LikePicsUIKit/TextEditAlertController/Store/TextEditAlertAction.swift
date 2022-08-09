//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

public enum TextEditAlertAction {
    case presented
    case textChanged(text: String)
    case saveActionTapped
    case cancelActionTapped
    case dismissed
}

extension TextEditAlertAction: Action {}
