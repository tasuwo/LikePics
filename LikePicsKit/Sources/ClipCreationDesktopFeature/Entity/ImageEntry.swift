//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation

@Observable
public class ImageEntry: Identifiable {
    public var id: UUID
    public var name: String
    public var data: Data
    public var width: CGFloat
    public var height: CGFloat
    public var index: Int?
    public var url: URL?

    public init(id: UUID, name: String, data: Data, width: CGFloat, height: CGFloat, index: Int? = nil, url: URL? = nil) {
        self.id = id
        self.name = name
        self.data = data
        self.width = width
        self.height = height
        self.index = index
        self.url = url
    }
}
