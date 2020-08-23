//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func showErrorMassage(_ message: String)
    func reload()
}

protocol ClipsListPresenter: AnyObject {
    var view: ClipsListViewProtocol? { get }
    var storage: ClipStorageProtocol { get }
    var clips: [Clip] { get set }

    func loadAllClips()
    static func resolveErrorMessage(_ error: ClipStorageError) -> String
}

extension ClipsListPresenter {
    func loadAllClips() {
        guard let view = self.view else { return }

        view.startLoading()
        switch self.storage.readAllClips() {
        case let .success(clips):
            self.clips = clips.sorted(by: { $0.registeredDate > $1.registeredDate })
            view.reload()
        case let .failure(error):
            view.showErrorMassage(Self.resolveErrorMessage(error))
        }
        view.endLoading()
    }
}
