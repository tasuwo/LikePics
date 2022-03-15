//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

extension Publisher where Self.Failure == Never {
    func waitUntilToBeTrue<P: Publisher>(_ other: P) -> AnyPublisher<Output, Never> where P.Output == Bool, P.Failure == Never {
        combineLatest(other)
            .filter { $0.1 }
            .map { $0.0 }
            .eraseToAnyPublisher()
    }
}
