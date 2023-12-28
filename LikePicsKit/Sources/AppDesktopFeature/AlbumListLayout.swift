//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import SwiftUI

enum AlbumListLayout {
    static let `default` = AlbumListLayout.column5
    static let spacing: CGFloat = 20

    case column6
    case column5
    case column4

    var numberOfColumns: Int {
        switch self {
        case .column6: 6
        case .column5: 5
        case .column4: 4
        }
    }

    var maxCellWidth: CGFloat {
        switch self {
        case .column6: 250
        case .column5: 232
        case .column4: 215
        }
    }

    var minCellWidth: CGFloat {
        switch self {
        case .column6: 190
        case .column5: 168
        case .column4: 156
        }
    }

    var maxRowWidth: CGFloat {
        CGFloat(integerLiteral: numberOfColumns) * maxCellWidth + CGFloat(integerLiteral: numberOfColumns - 1) * Self.spacing
    }

    var minRowWidth: CGFloat {
        CGFloat(integerLiteral: numberOfColumns) * minCellWidth + CGFloat(integerLiteral: numberOfColumns - 1) * Self.spacing
    }

    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: minCellWidth, maximum: maxRowWidth), spacing: Self.spacing), count: numberOfColumns)
    }

    static func layout(forWidth width: CGFloat) -> Self {
        if width > AlbumListLayout.column5.maxRowWidth {
            .column6
        } else if width > AlbumListLayout.column4.maxRowWidth {
            .column5
        } else {
            .column4
        }
    }
}
