//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol ClipListQuery {
    var clips: CurrentValueSubject<[Clip], Error> { get }
}
