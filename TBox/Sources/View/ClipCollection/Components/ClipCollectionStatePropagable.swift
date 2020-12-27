//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol ClipCollectionStatePropagable {
    var clips: CurrentValueSubject<[Clip], Never> { get }
    var selections: CurrentValueSubject<Set<Clip.Identity>, Never> { get }
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }
    var startShareForToolBar: PassthroughSubject<[Data], Never> { get }
}
