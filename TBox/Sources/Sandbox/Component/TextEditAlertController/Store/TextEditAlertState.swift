//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct TextEditAlertState: Equatable {
    let title: String?
    let message: String?
    let placeholder: String
    let text: String
    let shouldReturn: Bool

    // MARK: - Methods

    func updating(text: String, shouldReturn: Bool) -> Self {
        return .init(title: title,
                     message: message,
                     placeholder: placeholder,
                     text: text,
                     shouldReturn: shouldReturn)
    }
}
