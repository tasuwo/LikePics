//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListViewProtocol: AnyObject {
    func showErrorMassage(_ message: String)
}

protocol ClipsListPresenter: AnyObject {
    var view: ClipsListViewProtocol? { get }
    var storage: ClipStorageProtocol { get }
    var clips: [Clip] { get }

    static func resolveErrorMessage(_ error: ClipStorageError) -> String
}
