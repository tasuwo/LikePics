//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence

protocol ViewControllerFactory {
    func makeClipsViewController() -> ClipsViewController
    func makeClipDetailViewController(clip: Clip) -> ClipDetailViewController
}

class DependencyContainer {
    private lazy var clipsStorage = ClipStorage()
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeClipsViewController() -> ClipsViewController {
        let presenter = ClipsPresenter(storage: self.clipsStorage)
        return ClipsViewController(factory: self, presenter: presenter)
    }

    func makeClipDetailViewController(clip: Clip) -> ClipDetailViewController {
        let presenter = ClipDetailPresenter(clip: clip)
        return ClipDetailViewController(factory: self, presenter: presenter)
    }
}
