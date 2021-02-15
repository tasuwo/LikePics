//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

struct TextEditAlertState: Equatable {
    let id: UUID
    let title: String?
    let message: String?
    let placeholder: String
    let text: String
    let shouldReturn: Bool

    let isPresenting: Bool
}

extension TextEditAlertState {
    func updating(text: String) -> Self {
        return .init(id: id,
                     title: title,
                     message: message,
                     placeholder: placeholder,
                     text: text,
                     shouldReturn: shouldReturn,
                     isPresenting: isPresenting)
    }

    func updating(shouldReturn: Bool) -> Self {
        return .init(id: id,
                     title: title,
                     message: message,
                     placeholder: placeholder,
                     text: text,
                     shouldReturn: shouldReturn,
                     isPresenting: isPresenting)
    }

    func updating(isPresenting: Bool) -> Self {
        return .init(id: id,
                     title: title,
                     message: message,
                     placeholder: placeholder,
                     text: text,
                     shouldReturn: shouldReturn,
                     isPresenting: isPresenting)
    }
}
