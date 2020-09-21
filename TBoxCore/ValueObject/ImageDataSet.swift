//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

struct ImageDataSet {
    let index: Int

    let originalImageUrl: URL
    let originalImageData: Data
    let originalImageFileName: String

    let thumbnailUrl: URL?
    let thumbnailData: Data
    let thumbnailFileName: String

    let imageHeight: Double
    let imageWidth: Double

    // MARK: - Lifecycle

    init(dataSet: FetchedImageDataSet) {
        self.index = dataSet.index
        self.originalImageUrl = dataSet.original.url
        self.originalImageData = dataSet.original.data
        self.originalImageFileName = dataSet.original.fileName

        self.thumbnailUrl = dataSet.thumbnail?.url

        // TODO: サムネ用圧縮処理
        self.thumbnailData = dataSet.thumbnail?.data ?? dataSet.original.data

        if let fileName = dataSet.thumbnail?.fileName {
            self.thumbnailFileName = fileName != dataSet.original.fileName ? fileName : "thumb-\(dataSet.original.fileName)"
        } else {
            self.thumbnailFileName = "thumb-\(dataSet.original.fileName)"
        }

        self.imageWidth = dataSet.imageWidth
        self.imageHeight = dataSet.imageHeight
    }
}
