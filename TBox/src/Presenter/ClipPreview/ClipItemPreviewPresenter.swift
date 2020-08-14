//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

class ClipItemPreviewPresenter {
    let item: ClipItem

    private let storage: ClipStorageProtocol

    // MARK: - Lifecyle

    init(item: ClipItem, storage: ClipStorageProtocol) {
        self.item = item
        self.storage = storage
    }

    // MARK: - Methods

    func loadImageData() -> Data? {
        switch self.storage.getImageData(ofUrl: self.item.image.url, forClipUrl: self.item.clipUrl) {
        case let .success(data):
            return data
        case .failure:
            // TODO: Error Handling
            return nil
        }
    }
}
