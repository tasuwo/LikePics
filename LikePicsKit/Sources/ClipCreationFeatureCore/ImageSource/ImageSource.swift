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

    public init(fileURL: URL) {
        self.identifier = UUID()
        self.value = .fileURL(fileURL)
    }

    public init(data: LazyImageData) {
        self.identifier = UUID()
        self.value = .data(data)
    }
}

extension ImageSource {
    // MARK: - Equatable

    public static func == (lhs: ImageSource, rhs: ImageSource) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
