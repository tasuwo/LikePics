//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Smoothie
import TBoxCore
import TBoxUIKit
import UIKit

extension SceneDependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipCollectionViewController() -> UIViewController? {
        let state = ClipCollectionViewRootState(source: .all,
                                                isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let viewController = ClipCollectionViewController(state: state,
                                                          dependency: self,
                                                          thumbnailLoader: container.clipThumbnailLoader,
                                                          menuBuilder: ClipCollectionMenuBuilder(storage: container._userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagCollectionViewController() -> UIViewController? {
        let state = TagCollectionViewState(isSomeItemsHidden: container._userSettingStorage.readShowHiddenItems())
        let tagAdditionAlertState = TextEditAlertState(title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName)
        let tagEditAlertState = TextEditAlertState(title: L10n.tagListViewAlertForUpdateTitle,
                                                   message: L10n.tagListViewAlertForUpdateMessage,
                                                   placeholder: L10n.placeholderTagName)

        let viewController = TagCollectionViewController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         tagEditAlertState: tagEditAlertState,
                                                         dependency: self,
                                                         menuBuilder: TagCollectionMenuBuilder(storage: container._userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumListViewController() -> UIViewController? {
        let state = AlbumListViewState(isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let addAlbumAlertState = TextEditAlertState(title: L10n.albumListViewAlertForAddTitle,
                                                    message: L10n.albumListViewAlertForAddMessage,
                                                    placeholder: L10n.placeholderAlbumName)
        let editAlbumAlertState = TextEditAlertState(title: L10n.albumListViewAlertForEditTitle,
                                                     message: L10n.albumListViewAlertForEditMessage,
                                                     placeholder: L10n.placeholderAlbumName)

        let viewController = AlbumListViewController(state: state,
                                                     albumAdditionAlertState: addAlbumAlertState,
                                                     albumEditAlertState: editAlbumAlertState,
                                                     dependency: self,
                                                     thumbnailLoader: container.albumThumbnailLoader,
                                                     menuBuilder: AlbumListMenuBuilder.self)

        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchViewController() -> UIViewController? {
        let resultViewState = SearchResultViewState(isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let resultsController = SearchResultViewController(state: resultViewState,
                                                           dependency: self,
                                                           thumbnailLoader: container.temporaryThumbnailLoader)
        let entryViewState = SearchEntryViewState(isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems())
        let viewController = SearchEntryViewController(state: entryViewState,
                                                       dependency: self,
                                                       searchResultViewController: resultsController)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController() -> UIViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.main)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let state = SettingsViewState(cloudAvailability: nil,
                                      isSomeItemsHidden: !container._userSettingStorage.readShowHiddenItems(),
                                      isICloudSyncEnabled: container._userSettingStorage.readEnabledICloudSync())
        let store = Store(initialState: state, dependency: self, reducer: SettingsViewReducer())
        viewController.store = store

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController? {
        let store = ClipPreviewViewState(item: item)
        let viewController = ClipPreviewViewController(state: store, dependency: self)
        return viewController
    }
}
