//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ImageSource {
    enum Value {
        case urlSet(WebImageUrlSet)
        case rawData(Data)
    }

    let identifier: UUID
    let value: Value

    // MARK: - Lifecycle

    init(urlSet: WebImageUrlSet) {
        self.identifier = UUID()
        self.value = .urlSet(urlSet)
    }

    init(rawData: Data) {
        self.identifier = UUID()
        self.value = .rawData(rawData)
    }

    // MARK: - Methods

    func resolveSize() -> CGSize? {
        switch value {
        case let .rawData(data):
            return ImageUtility.resolveSize(for: data)

        case let .urlSet(urlSet):
            return ImageUtility.resolveSize(for: urlSet.url)
        }
    }

    var isValid: Bool {
        guard let size = self.resolveSize() else { return false }
        return size.height != 0
            && size.width != 0
            && size.height > 10
            && size.width > 10
    }
}
