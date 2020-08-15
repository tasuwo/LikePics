//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

extension String {
    public init(localizedKey: String, bundle: Bundle) {
        self = NSLocalizedString(localizedKey, tableName: "Localizable", bundle: bundle, value: "", comment: "")
    }
}
