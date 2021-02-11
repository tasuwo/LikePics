//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol HasTextEditAlertDelegate {
    var textEditAlertCancelled: () -> Void { get }
    var textEditAlertCompleted: (String) -> Void { get }
}
