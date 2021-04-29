//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ClipSearchFilterSetting: Equatable {
    public static let `default`: Self = .init(isHidden: nil, sort: .createdDate(.ascend))

    public let isHidden: Bool?
    public let sort: ClipSearchSort

    // MARK: - Initializers

    public init(isHidden: Bool?, sort: ClipSearchSort) {
        self.isHidden = isHidden
        self.sort = sort
    }
}
