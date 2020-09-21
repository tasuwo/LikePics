//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

struct ComposingFetchedImageDataSet {
    let original: FetchedImageData?
    let thumbnail: FetchedImageData?

    // MARK: - Lifecycle

    init(data: FetchedImageData) {
        switch data.quality {
        case .original:
            self.original = data
            self.thumbnail = nil
        case .thumbnail:
            self.original = nil
            self.thumbnail = data
        }
    }

    private init(original: FetchedImageData?, thumbnail: FetchedImageData?) {
        self.original = original
        self.thumbnail = thumbnail
    }

    // MARK: - Methods

    func setting(data: FetchedImageData) -> Self {
        switch data.quality {
        case .original:
            return ComposingFetchedImageDataSet(original: data, thumbnail: self.thumbnail)
        case .thumbnail:
            return ComposingFetchedImageDataSet(original: self.original, thumbnail: data)
        }
    }
}
