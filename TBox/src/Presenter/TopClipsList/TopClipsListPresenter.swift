//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func showErrorMassage(_ message: String)
    func reload()
}

class TopClipsListPresenter {
    enum ThumbnailLayer {
        case primary
        case secondary
        case tertiary
    }

    weak var view: TopClipsListViewProtocol?

    private let storage: ClipStorageProtocol

    private(set) var clips: [Clip] = []

    // MARK: - Lifecycle

    public init(storage: ClipStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Methods

    func reload() {
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

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        let nullableClipItem: ClipItem? = {
            switch layer {
            case .primary:
                return clip.primaryItem
            case .secondary:
                return clip.secondaryItem
            case .tertiary:
                return clip.tertiaryItem
            }
        }()
        guard let clipItem = nullableClipItem else { return nil }

        switch self.storage.getImageData(ofUrl: clipItem.thumbnail.url, forClipUrl: clip.url) {
        case let .success(data):
            return data
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
            return nil
        }
    }

    private static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO: Error Handling
        return "問題が発生しました"
    }
}
