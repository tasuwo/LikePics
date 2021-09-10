//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

extension String {
    var isUrlConvertible: Bool { URL(string: self) != nil }
}
