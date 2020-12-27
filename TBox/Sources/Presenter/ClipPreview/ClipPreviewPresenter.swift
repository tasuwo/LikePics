//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import UIKit

protocol ClipPreviewViewProtocol: AnyObject {}

class ClipPreviewPresenter {
    var item: ClipItem {
        self.query.clipItem.value
    }

    private let query: ClipItemQuery
    private let logger: TBoxLoggable

    weak var view: ClipPreviewViewProtocol?

    // MARK: - Lifecycle

    init(query: ClipItemQuery,
         logger: TBoxLoggable)
    {
        self.query = query
        self.logger = logger
    }
}
