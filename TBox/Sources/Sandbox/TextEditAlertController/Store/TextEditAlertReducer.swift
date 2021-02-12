//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

typealias TextEditAlertDependency = HasTextValidator

enum TextEditAlertReducer {
    typealias Dependency = TextEditAlertDependency
    typealias State = TextEditAlertState
    typealias Action = TextEditAlertAction
    typealias Effect = AnyPublisher<TextEditAlertAction?, Never>

    // MARK: - Methods

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, Effect?) {
        switch action {
        case let .textChanged(text: text):
            return (state.updating(text: text, shouldReturn: dependency.textValidator(text)), .none)

        case .saveActionTapped, .cancelActionTapped, .dismissed:
            return (state, .none)
        }
    }
}
