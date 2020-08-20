//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumViewProtocol: AnyObject {
    func showErrorMassage(_ message: String)
}

class AlbumPresenter {
    enum ThumbnailLayer {
        case primary
        case secondary
        case tertiary
    }

    weak var view: AlbumViewProtocol?

    private let storage: ClipStorageProtocol

    let album: Album

    // MARK: - Lifecycle

    init(album: Album, storage: ClipStorageProtocol) {
        self.album = album
        self.storage = storage
    }

    // MARK: - Methods

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
