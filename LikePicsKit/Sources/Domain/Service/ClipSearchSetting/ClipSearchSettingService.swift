//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol ClipSearchSettingService {
    func save(_ setting: ClipSearchSetting)
    func read() -> ClipSearchSetting?
    func query() -> AnyPublisher<ClipSearchSetting?, Never>
}
