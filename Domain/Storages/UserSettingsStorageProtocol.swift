//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol UserSettingsStorageProtocol {
    var showHiddenItems: AnyPublisher<Bool, Never> { get }
    var enabledICloudSync: AnyPublisher<Bool, Never> { get }
    func set(showHiddenItems: Bool)
    func set(enabledICloudSync: Bool)
}
