//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListReloadableViewProtocol: ClipsListViewProtocol {
    func startLoading()
    func endLoading()
    func reload()
}

protocol ClipsListReloadablePresenter: ClipsListPresenter {
    var reloadableView: ClipsListReloadableViewProtocol? { get }
    var clips: [Clip] { get set }

    func loadAllClips()
}

extension ClipsListReloadablePresenter {
    func loadAllClips() {
        guard let view = self.reloadableView else { return }

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
