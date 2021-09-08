//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension SceneRoot {
    enum SideBarItem: Int, CaseIterable {
        case top
        case search
        case tags
        case albums
        case setting

        var image: UIImage? {
            switch self {
            case .top:
                return UIImage(systemName: "house")

            case .search:
                return UIImage(systemName: "magnifyingglass")

            case .tags:
                return UIImage(systemName: "tag")

            case .albums:
                return UIImage(systemName: "square.stack")

            case .setting:
                return UIImage(systemName: "gear")
            }
        }

        var title: String {
            switch self {
            case .top:
                return L10n.appRootTabItemHome

            case .search:
                return L10n.appRootTabItemSearch

            case .tags:
                return L10n.appRootTabItemTag

            case .albums:
                return L10n.appRootTabItemAlbum

            case .setting:
                return L10n.appRootTabItemSettings
            }
        }

        func makeViewController(from intent: Intent?, by factory: ViewControllerFactory) -> RestorableViewController {
            let viewController: RestorableViewController
            switch self {
            case .top:
                if let homeViewState = intent?.homeViewState {
                    viewController = factory.makeClipCollectionViewController(homeViewState)
                } else {
                    viewController = factory.makeClipCollectionViewController(from: .all)
                }
                return UINavigationController(rootViewController: viewController)

            case .search:
                // swiftlint:disable:next force_unwrapping
                viewController = factory.makeSearchViewController(intent?.searchViewState)!

            case .tags:
                // swiftlint:disable:next force_unwrapping
                viewController = factory.makeTagCollectionViewController(intent?.tagCollectionViewState)!

            case .albums:
                // swiftlint:disable:next force_unwrapping
                viewController = factory.makeAlbumListViewController(intent?.albumLitViewState)!

            case .setting:
                viewController = factory.makeSettingsViewController(intent?.settingsViewState)
            }

            if case let .clips(state, preview: _) = intent {
                let clipCollectionViewController = factory.makeClipCollectionViewController(from: state.clipCollectionState.source)
                viewController.show(clipCollectionViewController, sender: nil)

                // TODO:
                // let previewPageViewController = factory.makeClipPreviewPageViewController(clips: .init(),
                //                                                                           source: state.clipCollectionState.source,
                //                                                                           indexPath: .init(clipIndex: 0, itemIndex: 0)) // TODO: 反映する
                // clipCollectionViewController.presentAfterLoad(previewPageViewController, animated: false, completion: nil)
            }

            return viewController
        }

        func map(to: SceneRoot.TabBarItem.Type) -> SceneRoot.TabBarItem {
            switch self {
            case .top:
                return .top

            case .search:
                return .search

            case .tags:
                return .tags

            case .albums:
                return .albums

            case .setting:
                return .setting
            }
        }
    }
}
