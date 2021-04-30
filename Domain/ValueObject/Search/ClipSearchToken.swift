//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ClipSearchToken: Equatable, Hashable, Codable {
    public enum Kind: String, Codable {
        case tag
        case album
    }

    public let kind: Kind
    public let id: UUID
    // TODO: どこかのタイミングでタイトルをCoreData側に合わせて更新するか、titleは保存しないように修正する
    public let title: String

    // MARK: - Initializers

    public init(kind: Kind, id: UUID, title: String) {
        self.kind = kind
        self.id = id
        self.title = title
    }
}
