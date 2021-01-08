//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol ClipCollectionStatePropagable {
    var clipsCount: AnyPublisher<Int, Never> { get }
    var selectionsCount: AnyPublisher<Int, Never> { get }
    var currentOperation: AnyPublisher<ClipCollection.Operation, Never> { get }
    var startShareForToolBar: AnyPublisher<[Data], Never> { get }
}
