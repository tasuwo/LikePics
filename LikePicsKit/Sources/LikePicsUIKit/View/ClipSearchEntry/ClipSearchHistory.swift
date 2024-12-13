//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ClipSearchHistory: Sendable {
    public let title: String
    public let sortName: String
    public let displaySettingName: String
    public let isDisplaySettingHidden: Bool

    public init(title: String, sortName: String, displaySettingName: String, isDisplaySettingHidden: Bool) {
        self.title = title
        self.sortName = sortName
        self.displaySettingName = displaySettingName
        self.isDisplaySettingHidden = isDisplaySettingHidden
    }
}
