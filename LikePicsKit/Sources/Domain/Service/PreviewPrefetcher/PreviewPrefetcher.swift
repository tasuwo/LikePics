//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol PreviewPrefetchable {
    var clip: CurrentValueSubject<Clip?, Never> { get }
}
