//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol ClipItemListQuery {
    var items: CurrentValueSubject<[ClipItem], Error> { get }
}
