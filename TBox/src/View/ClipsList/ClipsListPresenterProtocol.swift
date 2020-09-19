//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ThumbnailLayer {
    case primary
    case secondary
    case tertiary
}

protocol ClipsListPresenterProtocol {
    var clips: [Clip] { get }

    var selectedClips: [Clip] { get }

    var selectedIndices: [Int] { get }

    var isEditing: Bool { get }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data?

    func setEditing(_ editing: Bool)

    func select(at index: Int)

    func deselect(at index: Int)

    func deleteAll()
}

extension ClipsListPresenterProtocol where Self: ClipsListNavigationPresenterDataSource {
    // MARK: - ClipsListNavigationPresenterDataSource

    func clipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int {
        return self.clips.count
    }

    func selectedClipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int {
        return self.selectedClips.count
    }
}
