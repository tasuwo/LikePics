//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Persistence

protocol ViewControllerFactory {
    func makeClipsViewController() -> ClipsViewController
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
}
