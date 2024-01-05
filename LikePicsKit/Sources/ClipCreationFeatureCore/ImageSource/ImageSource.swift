//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreGraphics
import Domain
import Foundation

public struct ImageSource: Hashable {
    public enum Value {
        case webURL(WebImageUrlSet)
        case fileURL(URL)
        case data(LazyImageData)
    }

    public let identifier: UUID
    public let value: Value

    // MARK: - Lifecycle

    init(urlSet: WebImageUrlSet) {
        self.identifier = UUID()
        self.value = .webURL(urlSet)
    }

    init(fileURL: URL) {
        self.identifier = UUID()
        self.value = .fileURL(fileURL)
    }

    init(data: LazyImageData) {
        self.identifier = UUID()
        self.value = .data(data)
    }

    // MARK: - Methods

    public var isValid: Bool {
        switch value {
        case let .webURL(urlSet):
            guard let size = ImageUtility.resolveSize(for: urlSet.url) else { return false }
            return size.height != 0
                && size.width != 0
                && size.height > 10
                && size.width > 10

        default:
            return true
        }
    }
}

public extension ImageSource {
    // MARK: - Equatable

    static func == (lhs: ImageSource, rhs: ImageSource) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
