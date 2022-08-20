//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol UserSettingsStorageProtocol {
    var userInterfaceStyle: AnyPublisher<UserInterfaceStyle, Never> { get }
    var showHiddenItems: AnyPublisher<Bool, Never> { get }
    var enabledICloudSync: AnyPublisher<Bool, Never> { get }
    var ignoreCloudUnavailableAlert: AnyPublisher<Bool, Never> { get }
    var clipPreviewPlayConfiguration: AnyPublisher<ClipPreviewPlayConfiguration, Never> { get }

    func readUserInterfaceStyle() -> UserInterfaceStyle
    func readShowHiddenItems() -> Bool
    func readEnabledICloudSync() -> Bool
    func readIgnoreCloudUnavailableAlert() -> Bool
    func readClipPreviewPlayConfiguration() -> ClipPreviewPlayConfiguration

    func set(userInterfaceStyle: UserInterfaceStyle)
    func set(showHiddenItems: Bool)
    func set(enabledICloudSync: Bool)
    func set(ignoreCloudUnavailableAlert: Bool)
    func set(clipPreviewPlayConfiguration: ClipPreviewPlayConfiguration)
}
