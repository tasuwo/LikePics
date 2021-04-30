//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum ClipSearchSort: Equatable, Hashable {
    public enum Order: Equatable, Hashable {
        case ascend
        case descent

        public var isAscending: Bool {
            return self == .ascend
        }
    }

    case createdDate(Order)
    case updatedDate(Order)
    case size(Order)
}
