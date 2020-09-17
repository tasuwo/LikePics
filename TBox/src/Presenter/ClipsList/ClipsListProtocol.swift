//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListProtocol {
    var clips: [Clip] { get }
    var selectedClips: [Clip] { get }
    var selectedIndices: [Int] { get }
    var isEditing: Bool { get }
    var visibleHiddenClips: Bool { get set }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?
    mutating func set(delegate: ClipsListDelegate)
    mutating func loadAll()
    mutating func setEditing(_ isEditing: Bool)
    mutating func select(at index: Int)
    mutating func deselect(at index: Int)
    mutating func deleteSelectedClips()
    mutating func removeSelectedClips(from album: Album)
    mutating func hidesAll()
    mutating func unhidesAll()
}
