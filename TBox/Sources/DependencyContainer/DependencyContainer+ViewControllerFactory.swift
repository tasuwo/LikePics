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

extension DependencyContainer: ViewControllerFactory {
    // MARK: - ViewControllerFactory

    func makeTopClipCollectionViewController() -> UIViewController? {
        let state = ClipCollectionState(source: .all,
                                        sourceDescription: nil,
                                        layout: .waterfall,
                                        operation: .none,
                                        clips: .init(_values: [:],
                                                     _selectedIds: .init(),
                                                     _displayableIds: .init()),
                                        previewingClipId: nil,
                                        isEmptyMessageViewDisplaying: false,
                                        isCollectionViewDisplaying: false,
                                        alert: nil,
                                        isDismissed: false,
                                        isSomeItemsHidden: !userSettingStorage.readShowHiddenItems())
        let navigationBarState = ClipCollectionNavigationBarState(source: .all,
                                                                  layout: .waterfall,
                                                                  operation: .none,
                                                                  rightItems: [],
                                                                  leftItems: [],
                                                                  clipCount: 0,
                                                                  selectionCount: 0)
        let toolBarState = ClipCollectionToolBarState(source: .all,
                                                      operation: .none,
                                                      items: [],
                                                      isHidden: true,
                                                      parentState: state,
                                                      alert: nil)

        let viewController = ClipCollectionViewController(state: state,
                                                          navigationBarState: navigationBarState,
                                                          toolBarState: toolBarState,
                                                          dependency: self,
                                                          thumbnailLoader: clipThumbnailLoader,
                                                          menuBuilder: ClipCollectionMenuBuilder(storage: userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeTagCollectionViewController() -> UIViewController? {
        let state = TagCollectionViewState(tags: .init(_values: [:],
                                                       _selectedIds: .init(),
                                                       _displayableIds: .init()),
                                           searchQuery: "",
                                           isCollectionViewHidden: true,
                                           isEmptyMessageViewHidden: true,
                                           isSearchBarEnabled: false,
                                           alert: nil,
                                           _isSomeItemsHidden: _userSettingStorage.readShowHiddenItems(),
                                           _searchStorage: .init())
        let tagAdditionAlertState = TextEditAlertState(id: UUID(),
                                                       title: L10n.tagListViewAlertForAddTitle,
                                                       message: L10n.tagListViewAlertForAddMessage,
                                                       placeholder: L10n.placeholderTagName,
                                                       text: "",
                                                       shouldReturn: false,
                                                       isPresenting: false)
        let tagEditAlertState = TextEditAlertState(id: UUID(),
                                                   title: L10n.tagListViewAlertForUpdateTitle,
                                                   message: L10n.tagListViewAlertForUpdateMessage,
                                                   placeholder: L10n.placeholderTagName,
                                                   text: "",
                                                   shouldReturn: false,
                                                   isPresenting: false)

        let viewController = TagCollectionViewController(state: state,
                                                         tagAdditionAlertState: tagAdditionAlertState,
                                                         tagEditAlertState: tagEditAlertState,
                                                         dependency: self,
                                                         menuBuilder: TagCollectionMenuBuilder(storage: userSettingStorage))

        return UINavigationController(rootViewController: viewController)
    }

    func makeAlbumListViewController() -> UIViewController? {
        let state = AlbumListViewState(searchQuery: "",
                                       albums: .init(_values: [:],
                                                     _selectedIds: .init(),
                                                     _displayableIds: .init()),
                                       isEditing: false,
                                       isEmptyMessageViewDisplaying: false,
                                       isCollectionViewDisplaying: false,
                                       isSearchBarEnabled: false,
                                       isAddButtonEnabled: true,
                                       isDragInteractionEnabled: false,
                                       alert: nil,
                                       _isSomeItemsHidden: !userSettingStorage.readShowHiddenItems(),
                                       _searchStorage: .init())
        let addAlbumAlertState = TextEditAlertState(id: UUID(),
                                                    title: L10n.albumListViewAlertForAddTitle,
                                                    message: L10n.albumListViewAlertForAddMessage,
                                                    placeholder: L10n.placeholderAlbumName,
                                                    text: "",
                                                    shouldReturn: false,
                                                    isPresenting: false)
        let editAlbumAlertState = TextEditAlertState(id: UUID(),
                                                     title: L10n.albumListViewAlertForEditTitle,
                                                     message: L10n.albumListViewAlertForEditMessage,
                                                     placeholder: L10n.placeholderAlbumName,
                                                     text: "",
                                                     shouldReturn: false,
                                                     isPresenting: false)

        let viewController = AlbumListViewController(state: state,
                                                     albumAdditionAlertState: addAlbumAlertState,
                                                     albumEditAlertState: editAlbumAlertState,
                                                     dependency: self,
                                                     thumbnailLoader: albumThumbnailLoader,
                                                     menuBuilder: AlbumListMenuBuilder.self)

        return UINavigationController(rootViewController: viewController)
    }

    func makeSearchViewController() -> UIViewController? {
        let resultsController = SearchResultViewController(state: .init(isSomeItemsHidden: !_userSettingStorage.readShowHiddenItems()),
                                                           dependency: self,
                                                           thumbnailLoader: temporaryThumbnailLoader)
        let viewController = SearchEntryViewController(state: .init(searchHistories: [],
                                                                    isSomeItemsHidden: !_userSettingStorage.readShowHiddenItems(),
                                                                    alert: nil),
                                                       dependency: self,
                                                       searchResultViewController: resultsController)
        return UINavigationController(rootViewController: viewController)
    }

    func makeSettingsViewController() -> UIViewController {
        let storyBoard = UIStoryboard(name: "SettingsViewController", bundle: Bundle.main)

        // swiftlint:disable:next force_cast
        let viewController = storyBoard.instantiateViewController(identifier: "SettingsViewController") as! SettingsViewController

        let presenter = SettingsPresenter(storage: self._userSettingStorage,
                                          availabilityStore: self.cloudAvailabilityObserver)
        viewController.factory = self
        viewController.presenter = presenter

        return UINavigationController(rootViewController: viewController)
    }

    func makeClipPreviewViewController(for item: ClipItem) -> ClipPreviewViewController? {
        let store = ClipPreviewViewState(itemId: item.id,
                                         imageId: item.imageId,
                                         imageSize: item.imageSize.cgSize,
                                         source: nil,
                                         isDisplayingLoadingIndicator: false,
                                         isUserInteractionEnabled: true,
                                         isDismissed: false)
        let viewController = ClipPreviewViewController(state: store, dependency: self)
        return viewController
    }
}
