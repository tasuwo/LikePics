//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol ClipQuery {
    var clip: CurrentValueSubject<Clip, Error> { get }
}
