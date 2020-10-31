//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Persistence
import TBoxCore

protocol ViewControllerFactory {
    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController
    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController
}

class DependencyContainer {
    private let clipStore: ClipStorable
    private let clipViewer: ClipViewable
    private let finder = WebImageUrlFinder()
    private let currentDateResolver = { Date() }

    init() throws {
        let logger = RootLogger.shared
        let imageStorage = try ImageStorage(configuration: .temporary)
        let lightweightClipStorage = try LightweightClipStorage(config: .group, logger: logger)
        let clipStorage = try ClipStorage(config: .group, logger: logger)
        self.clipStore = TemporaryClipCommandService(clipStorage: clipStorage,
                                                     lightweightClipStorage: lightweightClipStorage,
                                                     imageStorage: imageStorage,
                                                     logger: logger)
        self.clipViewer = lightweightClipStorage
    }
}

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeShareNavigationRootViewController() -> ShareNavigationRootViewController {
        let presenter = ShareNavigationRootPresenter()
        return ShareNavigationRootViewController(factory: self, presenter: presenter)
    }

    func makeClipTargetCollectionViewController(url: URL, delegate: ClipTargetFinderDelegate) -> ClipTargetFinderViewController {
        let presenter = ClipTargetFinderPresenter(url: url,
                                                  clipStore: self.clipStore,
                                                  clipViewer: self.clipViewer,
                                                  finder: self.finder,
                                                  currentDateResolver: currentDateResolver)
        return ClipTargetFinderViewController(presenter: presenter, delegate: delegate)
    }
}

extension TemporaryClipCommandService: ClipStorable {}
extension LightweightClipStorage: ClipViewable {
    // MARK: - ClipViewable

    public func clip(havingUrl url: URL) -> Result<TransferringClip?, Error> {
        switch self.readClip(havingUrl: url) {
        case .success(.none):
            return .success(nil)

        case let .success(.some(clip)):
            return .success(.init(id: clip.id,
                                  url: clip.url,
                                  description: clip.description,
                                  tags: clip.tags.map {
                                      TransferringClip.Tag(id: $0.id, name: $0.name)
                                  },
                                  isHidden: clip.isHidden,
                                  registeredDate: clip.registeredDate))

        case let .failure(error):
            return .failure(error)
        }
    }
}
