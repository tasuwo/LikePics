//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

enum ClipListLayout {
    static let `default` = ClipListLayout.column5
    static let spacing: CGFloat = 20

    case column7
    case column6
    case column5
    case column4
    case column3
    case column2

    var numberOfColumns: Int {
        switch self {
        case .column7: 7
        case .column6: 6
        case .column5: 5
        case .column4: 4
        case .column3: 3
        case .column2: 2
        }
    }

    var maxCellWidth: CGFloat {
        switch self {
        case .column7: 269
        case .column6: 250
        case .column5: 232
        case .column4: 215
        case .column3: 199
        case .column2: 184
        }
    }

    var minCellWidth: CGFloat {
        switch self {
        case .column7: 222
        case .column6: 190
        case .column5: 168
        case .column4: 156
        case .column3: 150
        case .column2: 147
        }
    }

    var spacing: CGFloat {
        switch self {
        case .column7: 20
        case .column6: 18
        case .column5: 16
        case .column4: 14
        case .column3: 12
        case .column2: 10
        }
    }

    var maxRowWidth: CGFloat {
        CGFloat(integerLiteral: numberOfColumns) * maxCellWidth + CGFloat(integerLiteral: numberOfColumns - 1) * Self.spacing
    }

    var minRowWidth: CGFloat {
        CGFloat(integerLiteral: numberOfColumns) * minCellWidth + CGFloat(integerLiteral: numberOfColumns - 1) * Self.spacing
    }

    static func layout(forWidth width: CGFloat) -> Self {
        if width > ClipListLayout.column6.maxRowWidth {
            .column7
        } else if width > ClipListLayout.column5.maxRowWidth {
            .column6
        } else if width > ClipListLayout.column4.maxRowWidth {
            .column5
        } else if width > ClipListLayout.column3.maxRowWidth {
            .column4
        } else if width > ClipListLayout.column2.maxRowWidth {
            .column3
        } else {
            .column2
        }
    }
}
