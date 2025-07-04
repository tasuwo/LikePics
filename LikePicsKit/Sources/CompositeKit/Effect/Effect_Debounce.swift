//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

extension Effect {
    public func debounce<S: Scheduler>(
        id: UUID,
        for time: S.SchedulerTimeType.Stride,
        scheduler: S,
        options: S.SchedulerOptions? = nil
    ) -> Effect {
        let upstream = Just(())
            .delay(for: time, scheduler: scheduler, options: options)
            .flatMap { [upstream] in upstream }
            .eraseToAnyPublisher()
        return .init(
            id: id,
            publisher: upstream,
            underlying: underlyingObject,
            completeWith: actionAtCompleted
        )
    }
}
