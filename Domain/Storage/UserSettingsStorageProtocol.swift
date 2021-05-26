//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol UserSettingsStorageProtocol {
    var userInterfaceStyle: AnyPublisher<UserInterfaceStyle, Never> { get }
    var showHiddenItems: AnyPublisher<Bool, Never> { get }
    var enabledICloudSync: AnyPublisher<Bool, Never> { get }
    func readUserInterfaceStyle() -> UserInterfaceStyle
    func readShowHiddenItems() -> Bool
    func readEnabledICloudSync() -> Bool
    func set(userInterfaceStyle: UserInterfaceStyle)
    func set(showHiddenItems: Bool)
    func set(enabledICloudSync: Bool)
}
