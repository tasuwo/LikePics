//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol ClipSearchSettingService {
    func save(_ setting: ClipSearchSetting)
    func query() -> AnyPublisher<ClipSearchSetting?, Never>
}
