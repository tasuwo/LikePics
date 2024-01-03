//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation

extension Observable {
    func observe<Member>(
        _ keyPath: KeyPath<Self, Member>,
        onChange: @MainActor @escaping @Sendable (Member, Member) -> Void
    ) {
        continuousObservationTracking {
            self[keyPath: keyPath]
        } onChange: {
            let oldValue = self[keyPath: keyPath]
            Task.detached { @MainActor in
                let newValue = self[keyPath: keyPath]
                onChange(oldValue, newValue)
            }
        }
    }

    private func continuousObservationTracking<T>(
        _ apply: @escaping () -> T,
        onChange: @escaping (@Sendable () -> Void)
    ) {
        _ = withObservationTracking(apply, onChange: {
            onChange()
            continuousObservationTracking(apply, onChange: onChange)
        })
    }
}
