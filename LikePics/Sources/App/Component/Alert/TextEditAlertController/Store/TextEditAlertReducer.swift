//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit

typealias TextEditAlertDependency = HasTextValidator
    & HasTextEditAlertDelegate

struct TextEditAlertReducer: Reducer {
    typealias Dependency = TextEditAlertDependency
    typealias State = TextEditAlertState
    typealias Action = TextEditAlertAction

    // MARK: - Methods

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        case .presented:
            return (state.updating(isPresenting: true), .none)

        case let .textChanged(text: text):
            let newState = state
                .updating(text: text)
                .updating(shouldReturn: dependency.textValidator(text))
            return (newState, .none)

        case .saveActionTapped:
            dependency.textEditAlertDelegate?.textEditAlert(state.id, didTapSaveWithText: state.text)
            return (state.updating(isPresenting: false), .none)

        case .cancelActionTapped, .dismissed:
            dependency.textEditAlertDelegate?.textEditAlertDidCancel(state.id)
            return (state.updating(isPresenting: false), .none)
        }
    }
}
