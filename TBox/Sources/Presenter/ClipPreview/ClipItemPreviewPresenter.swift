//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import UIKit

protocol ClipItemPreviewViewProtocol: AnyObject {}

class ClipItemPreviewPresenter {
    var item: ClipItem {
        self.query.clipItem.value
    }

    private let query: ClipItemQuery
    private let logger: TBoxLoggable

    weak var view: ClipItemPreviewViewProtocol?

    // MARK: - Lifecycle

    init(query: ClipItemQuery,
         logger: TBoxLoggable)
    {
        self.query = query
        self.logger = logger
    }
}
