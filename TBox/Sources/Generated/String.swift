// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// このアルバムの名前を入力してください
    internal static let albumListViewAlertForAddMessage = L10n.tr("Localizable", "album_list_view_alert_for_add_message")
    /// アルバム名
    internal static let albumListViewAlertForAddPlaceholder = L10n.tr("Localizable", "album_list_view_alert_for_add_placeholder")
    /// 新規アルバム
    internal static let albumListViewAlertForAddTitle = L10n.tr("Localizable", "album_list_view_alert_for_add_title")
    /// アルバムを削除
    internal static let albumListViewAlertForDeleteAction = L10n.tr("Localizable", "album_list_view_alert_for_delete_action")
    /// アルバム"%@"を削除しますか？\n含まれるクリップは削除されません
    internal static func albumListViewAlertForDeleteMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "album_list_view_alert_for_delete_message", String(describing: p1))
    }

    /// "%@"を削除
    internal static func albumListViewAlertForDeleteTitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "album_list_view_alert_for_delete_title", String(describing: p1))
    }

    /// はじめてのアルバムを追加する
    internal static let albumListViewEmptyActionTitle = L10n.tr("Localizable", "album_list_view_empty_action_title")
    /// 複数のクリップをアルバムにまとめることができます
    internal static let albumListViewEmptyMessage = L10n.tr("Localizable", "album_list_view_empty_message")
    /// アルバムがありません
    internal static let albumListViewEmptyTitle = L10n.tr("Localizable", "album_list_view_empty_title")
    /// アルバムの追加に失敗しました
    internal static let albumListViewErrorAtAddAlbum = L10n.tr("Localizable", "album_list_view_error_at_add_album")
    /// アルバムの削除に失敗しました
    internal static let albumListViewErrorAtDeleteAlbum = L10n.tr("Localizable", "album_list_view_error_at_delete_album")
    /// アルバムの読み込みに失敗しました
    internal static let albumListViewErrorAtReadAlbums = L10n.tr("Localizable", "album_list_view_error_at_read_albums")
    /// 画像の読み込みに失敗しました
    internal static let albumListViewErrorAtReadImageData = L10n.tr("Localizable", "album_list_view_error_at_read_image_data")
    /// アルバム
    internal static let albumListViewTitle = L10n.tr("Localizable", "album_list_view_title")
    /// はじめてのアルバムを追加する
    internal static let albumSelectionViewEmptyActionTitle = L10n.tr("Localizable", "album_selection_view_empty_action_title")
    /// 複数のクリップをアルバムにまとめることができます
    internal static let albumSelectionViewEmptyMessage = L10n.tr("Localizable", "album_selection_view_empty_message")
    /// アルバムがありません
    internal static let albumSelectionViewEmptyTitle = L10n.tr("Localizable", "album_selection_view_empty_title")
    /// アルバムへ追加
    internal static let albumSelectionViewTitle = L10n.tr("Localizable", "album_selection_view_title")
    /// アルバム内にクリップがありません
    internal static let albumViewEmptyTitle = L10n.tr("Localizable", "album_view_empty_title")
    /// アルバム
    internal static let appRootTabItemAlbum = L10n.tr("Localizable", "app_root_tab_item_album")
    /// ホーム
    internal static let appRootTabItemHome = L10n.tr("Localizable", "app_root_tab_item_home")
    /// 検索
    internal static let appRootTabItemSearch = L10n.tr("Localizable", "app_root_tab_item_search")
    /// 設定
    internal static let appRootTabItemSettings = L10n.tr("Localizable", "app_root_tab_item_settings")
    /// タグ
    internal static let appRootTabItemTag = L10n.tr("Localizable", "app_root_tab_item_tag")
    /// アルバムへの追加に失敗しました
    internal static let clipCollectionErrorAtAddClipToAlbum = L10n.tr("Localizable", "clip_collection_error_at_add_clip_to_album")
    /// アルバムへの追加に失敗しました
    internal static let clipCollectionErrorAtAddClipsToAlbum = L10n.tr("Localizable", "clip_collection_error_at_add_clips_to_album")
    /// クリップの削除に失敗しました
    internal static let clipCollectionErrorAtDeleteClip = L10n.tr("Localizable", "clip_collection_error_at_delete_clip")
    /// クリップの削除に失敗しました
    internal static let clipCollectionErrorAtDeleteClips = L10n.tr("Localizable", "clip_collection_error_at_delete_clips")
    /// クリップの更新に失敗しました
    internal static let clipCollectionErrorAtHideClip = L10n.tr("Localizable", "clip_collection_error_at_hide_clip")
    /// クリップの更新に失敗しました
    internal static let clipCollectionErrorAtHideClips = L10n.tr("Localizable", "clip_collection_error_at_hide_clips")
    /// クリップの分割に失敗しました
    internal static let clipCollectionErrorAtPurge = L10n.tr("Localizable", "clip_collection_error_at_purge")
    /// アルバムからの削除に失敗しました
    internal static let clipCollectionErrorAtRemoveClipsFromAlbum = L10n.tr("Localizable", "clip_collection_error_at_remove_clips_from_album")
    /// クリップ内の画像の削除に失敗しました
    internal static let clipCollectionErrorAtRemoveItemFromClip = L10n.tr("Localizable", "clip_collection_error_at_remove_item_from_clip")
    /// 並び替えに失敗しました
    internal static let clipCollectionErrorAtReorder = L10n.tr("Localizable", "clip_collection_error_at_reorder")
    /// 共有に失敗しました
    internal static let clipCollectionErrorAtShare = L10n.tr("Localizable", "clip_collection_error_at_share")
    /// クリップの更新に失敗しました
    internal static let clipCollectionErrorAtUnhideClip = L10n.tr("Localizable", "clip_collection_error_at_unhide_clip")
    /// クリップの更新に失敗しました
    internal static let clipCollectionErrorAtUnhideClips = L10n.tr("Localizable", "clip_collection_error_at_unhide_clips")
    /// タグの更新に失敗しました
    internal static let clipCollectionErrorAtUpdateTagsToClip = L10n.tr("Localizable", "clip_collection_error_at_update_tags_to_clip")
    /// タグの更新に失敗しました
    internal static let clipCollectionErrorAtUpdateTagsToClips = L10n.tr("Localizable", "clip_collection_error_at_update_tags_to_clips")
    /// 画像を選択
    internal static let clipCreationViewTitle = L10n.tr("Localizable", "clip_creation_view_title")
    /// 画像の読み込みに失敗しました
    internal static let clipInformationErrorAtReadClip = L10n.tr("Localizable", "clip_information_error_at_read_clip")
    /// タグの削除に失敗しました
    internal static let clipInformationErrorAtRemoveTags = L10n.tr("Localizable", "clip_information_error_at_remove_tags")
    /// タグの更新に失敗しました
    internal static let clipInformationErrorAtReplaceTags = L10n.tr("Localizable", "clip_information_error_at_replace_tags")
    /// 更新に失敗しました
    internal static let clipInformationErrorAtUpdateHidden = L10n.tr("Localizable", "clip_information_error_at_update_hidden")
    /// URLの更新に失敗しました
    internal static let clipInformationErrorAtUpdateSiteUrl = L10n.tr("Localizable", "clip_information_error_at_update_site_url")
    /// 削除
    internal static let clipInformationViewAlertForDeleteTagAction = L10n.tr("Localizable", "clip_information_view_alert_for_delete_tag_action")
    /// このタグを削除しますか？\nクリップ及び画像は削除されません
    internal static let clipInformationViewAlertForDeleteTagMessage = L10n.tr("Localizable", "clip_information_view_alert_for_delete_tag_message")
    /// 保存に失敗しました
    internal static let clipMergeViewErrorAtMerge = L10n.tr("Localizable", "clip_merge_view_error_at_merge")
    /// 画像をクリップにまとめる
    internal static let clipMergeViewTitle = L10n.tr("Localizable", "clip_merge_view_title")
    /// 画像の読み込みに失敗しました
    internal static let clipPreviewErrorAtLoadImage = L10n.tr("Localizable", "clip_preview_error_at_load_image")
    /// クリップの読み込みに失敗しました
    internal static let clipPreviewPageViewErrorAtReadClip = L10n.tr("Localizable", "clip_preview_page_view_error_at_read_clip")
    /// タグを追加する
    internal static let clipPreviewViewAlertForAddTag = L10n.tr("Localizable", "clip_preview_view_alert_for_add_tag")
    /// アルバムに追加する
    internal static let clipPreviewViewAlertForAddToAlbum = L10n.tr("Localizable", "clip_preview_view_alert_for_add_to_album")
    /// クリップを削除する
    internal static let clipPreviewViewAlertForDeleteClipAction = L10n.tr("Localizable", "clip_preview_view_alert_for_delete_clip_action")
    /// 画像を削除する
    internal static let clipPreviewViewAlertForDeleteClipItemAction = L10n.tr("Localizable", "clip_preview_view_alert_for_delete_clip_item_action")
    /// クリップを削除すると、このクリップに含まれる全ての画像も同時に削除されます
    internal static let clipPreviewViewAlertForDeleteMessage = L10n.tr("Localizable", "clip_preview_view_alert_for_delete_message")
    /// この画像の保存元のサイトのURLを入力してください
    internal static let clipPreviewViewAlertForEditSiteUrlMessage = L10n.tr("Localizable", "clip_preview_view_alert_for_edit_site_url_message")
    /// https://www...
    internal static let clipPreviewViewAlertForEditSiteUrlPlaceholder = L10n.tr("Localizable", "clip_preview_view_alert_for_edit_site_url_placeholder")
    /// サイトのURL
    internal static let clipPreviewViewAlertForEditSiteUrlTitle = L10n.tr("Localizable", "clip_preview_view_alert_for_edit_site_url_title")
    /// 隠す
    internal static let clipPreviewViewAlertForHideAction = L10n.tr("Localizable", "clip_preview_view_alert_for_hide_action")
    /// このクリップは、設定が有効な間は全ての場所から隠されます
    internal static let clipPreviewViewAlertForHideMessage = L10n.tr("Localizable", "clip_preview_view_alert_for_hide_message")
    /// 正常に削除しました
    internal static let clipPreviewViewAlertForSuccessfullyDeleteMessage = L10n.tr("Localizable", "clip_preview_view_alert_for_successfully_delete_message")
    /// 画像の読み込みに失敗しました。クリップしなおしてください
    internal static let clipPreviewViewErrorAtReadImage = L10n.tr("Localizable", "clip_preview_view_error_at_read_image")
    /// タグを追加する
    internal static let clipsListAlertForAddTag = L10n.tr("Localizable", "clips_list_alert_for_add_tag")
    /// アルバムに追加する
    internal static let clipsListAlertForAddToAlbum = L10n.tr("Localizable", "clips_list_alert_for_add_to_album")
    /// %d件のクリップを隠す
    internal static func clipsListAlertForChangeVisibilityHideAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_change_visibility_hide_action", p1)
    }

    /// 隠したクリップは、設定が有効な間は全ての場所から隠されます
    internal static let clipsListAlertForChangeVisibilityMessage = L10n.tr("Localizable", "clips_list_alert_for_change_visibility_message")
    /// %d件のクリップを表示する
    internal static func clipsListAlertForChangeVisibilityUnhideAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_change_visibility_unhide_action", p1)
    }

    /// %d件のクリップを削除
    internal static func clipsListAlertForDeleteAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_delete_action", p1)
    }

    /// 削除
    internal static let clipsListAlertForDeleteInAlbumActionDelete = L10n.tr("Localizable", "clips_list_alert_for_delete_in_album_action_delete")
    /// アルバムから削除
    internal static let clipsListAlertForDeleteInAlbumActionRemoveFromAlbum = L10n.tr("Localizable", "clips_list_alert_for_delete_in_album_action_remove_from_album")
    /// これらのクリップを削除、あるいはアルバムから削除しますか？
    internal static let clipsListAlertForDeleteInAlbumMessage = L10n.tr("Localizable", "clips_list_alert_for_delete_in_album_message")
    /// クリップを削除すると、クリップに含まれる全ての画像も同時に削除されます
    internal static let clipsListAlertForDeleteMessage = L10n.tr("Localizable", "clips_list_alert_for_delete_message")
    /// この画像のみ共有する
    internal static let clipsListAlertForShareItemAction = L10n.tr("Localizable", "clips_list_alert_for_share_item_action")
    /// クリップ内の%d件の画像を共有する
    internal static func clipsListAlertForShareItemsAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_share_items_action", p1)
    }

    /// タグを追加
    internal static let clipsListContextMenuAddTag = L10n.tr("Localizable", "clips_list_context_menu_add_tag")
    /// アルバムへ追加
    internal static let clipsListContextMenuAddToAlbum = L10n.tr("Localizable", "clips_list_context_menu_add_to_album")
    /// 削除
    internal static let clipsListContextMenuDelete = L10n.tr("Localizable", "clips_list_context_menu_delete")
    /// 隠す
    internal static let clipsListContextMenuHide = L10n.tr("Localizable", "clips_list_context_menu_hide")
    /// 分割
    internal static let clipsListContextMenuPurge = L10n.tr("Localizable", "clips_list_context_menu_purge")
    /// アルバムから削除
    internal static let clipsListContextMenuRemoveFromAlbum = L10n.tr("Localizable", "clips_list_context_menu_remove_from_album")
    /// 共有
    internal static let clipsListContextMenuShare = L10n.tr("Localizable", "clips_list_context_menu_share")
    /// 表示する
    internal static let clipsListContextMenuUnhide = L10n.tr("Localizable", "clips_list_context_menu_unhide")
    /// 全て選択解除
    internal static let clipsListRightBarItemForDeselectAllTitle = L10n.tr("Localizable", "clips_list_right_bar_item_for_deselect_all_title")
    /// 完了
    internal static let clipsListRightBarItemForDone = L10n.tr("Localizable", "clips_list_right_bar_item_for_done")
    /// 並び替え
    internal static let clipsListRightBarItemForReorder = L10n.tr("Localizable", "clips_list_right_bar_item_for_reorder")
    /// 全て選択
    internal static let clipsListRightBarItemForSelectAllTitle = L10n.tr("Localizable", "clips_list_right_bar_item_for_select_all_title")
    /// 選択
    internal static let clipsListRightBarItemForSelectTitle = L10n.tr("Localizable", "clips_list_right_bar_item_for_select_title")
    /// キャンセル
    internal static let confirmAlertCancel = L10n.tr("Localizable", "confirm_alert_cancel")
    /// OK
    internal static let confirmAlertOk = L10n.tr("Localizable", "confirm_alert_ok")
    /// 保存
    internal static let confirmAlertSave = L10n.tr("Localizable", "confirm_alert_save")
    /// 以前利用していたiCloudアカウントと異なるアカウントでログインされています。\nこの端末上に保存されているデータは、現在ログイン中のiCloudアカウントに保存されているデータと統合されます
    internal static let errorIcloudAccountChangedMessage = L10n.tr("Localizable", "error_icloud_account_changed_message")
    /// iCloudアカウントが異なります
    internal static let errorIcloudAccountChangedTitle = L10n.tr("Localizable", "error_icloud_account_changed_title")
    /// しばらく時間を置いてから再度お試しください
    internal static let errorIcloudDefaultMessage = L10n.tr("Localizable", "error_icloud_default_message")
    /// iCloudが利用できません
    internal static let errorIcloudDefaultTitle = L10n.tr("Localizable", "error_icloud_default_title")
    /// iCloudアカウントでログインしていないか、端末のiCloud同期設定がオフになっている可能性があります。\niCluoudが利用できない間に保存したデータは、後ほどiCloudが有効になった際に統合されます
    internal static let errorIcloudUnavailableMessage = L10n.tr("Localizable", "error_icloud_unavailable_message")
    /// iCloudが利用できません
    internal static let errorIcloudUnavailableTitle = L10n.tr("Localizable", "error_icloud_unavailable_title")
    /// iCloud同期を利用しない
    internal static let errorIcloudUnavailableTurnOffAction = L10n.tr("Localizable", "error_icloud_unavailable_turn_off_action")
    /// iCloud同期を自動で有効にする
    internal static let errorIcloudUnavailableTurnOnAction = L10n.tr("Localizable", "error_icloud_unavailable_turn_on_action")
    /// タグの追加に失敗しました
    internal static let errorTagAddDefault = L10n.tr("Localizable", "error_tag_add_default")
    /// 同名のタグを追加することはできません
    internal static let errorTagAddDuplicated = L10n.tr("Localizable", "error_tag_add_duplicated")
    /// タグの削除に失敗しました
    internal static let errorTagDelete = L10n.tr("Localizable", "error_tag_delete")
    /// タグの読み込みに失敗しました
    internal static let errorTagRead = L10n.tr("Localizable", "error_tag_read")
    /// クリップの更新に失敗しました
    internal static let errorTagRenameDefault = L10n.tr("Localizable", "error_tag_rename_default")
    /// 同じ名前のタグが既に存在します
    internal static let errorTagRenameDuplicated = L10n.tr("Localizable", "error_tag_rename_duplicated")
    /// 検索に失敗しました
    internal static let searchEntryViewErrorAtSearch = L10n.tr("Localizable", "search_entry_view_error_at_search")
    /// キーワード
    internal static let searchEntryViewSearchBarPlaceholder = L10n.tr("Localizable", "search_entry_view_search_bar_placeholder")
    /// 検索
    internal static let searchEntryViewTitle = L10n.tr("Localizable", "search_entry_view_title")
    /// キーワード「%@」に一致するクリップは見つかりませんでした
    internal static func searchResultForKeywordsEmptyTitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "search_result_for_keywords_empty_title", String(describing: p1))
    }

    /// タグ「%@」が付与されたクリップはありません
    internal static func searchResultForTagEmptyTitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "search_result_for_tag_empty_title", String(describing: p1))
    }

    /// 未分類のクリップはありません
    internal static let searchResultForUncategorizedEmptyTitle = L10n.tr("Localizable", "search_result_for_uncategorized_empty_title")
    /// 未分類
    internal static let searchResultTitleUncategorized = L10n.tr("Localizable", "search_result_title_uncategorized")
    /// この端末に保存したデータを他のiOS/iPadOS端末と共有できなくなります。同期がオフの最中に保存したデータは、後ほどiCloud同期が有効になった際に、他のiOS/iPadOS端末のデータと統合されます
    internal static let settingsConfirmIcloudSyncOffMessage = L10n.tr("Localizable", "settings_confirm_icloud_sync_off_message")
    /// iCloud同期をオフにしますか？
    internal static let settingsConfirmIcloudSyncOffTitle = L10n.tr("Localizable", "settings_confirm_icloud_sync_off_title")
    /// このタグの名前を入力してください
    internal static let tagListViewAlertForAddMessage = L10n.tr("Localizable", "tag_list_view_alert_for_add_message")
    /// タグ名
    internal static let tagListViewAlertForAddPlaceholder = L10n.tr("Localizable", "tag_list_view_alert_for_add_placeholder")
    /// 新規タグ
    internal static let tagListViewAlertForAddTitle = L10n.tr("Localizable", "tag_list_view_alert_for_add_title")
    /// %d件のタグを削除
    internal static func tagListViewAlertForDeleteAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "tag_list_view_alert_for_delete_action", p1)
    }

    /// 選択中のタグを削除しますか？\n含まれるクリップは削除されません
    internal static let tagListViewAlertForDeleteMessage = L10n.tr("Localizable", "tag_list_view_alert_for_delete_message")
    /// このタグの新しい名前を入力してください
    internal static let tagListViewAlertForUpdateMessage = L10n.tr("Localizable", "tag_list_view_alert_for_update_message")
    /// タグ名
    internal static let tagListViewAlertForUpdatePlaceholder = L10n.tr("Localizable", "tag_list_view_alert_for_update_placeholder")
    /// タグ名の変更
    internal static let tagListViewAlertForUpdateTitle = L10n.tr("Localizable", "tag_list_view_alert_for_update_title")
    /// コピー
    internal static let tagListViewContextMenuActionCopy = L10n.tr("Localizable", "tag_list_view_context_menu_action_copy")
    /// 削除
    internal static let tagListViewContextMenuActionDelete = L10n.tr("Localizable", "tag_list_view_context_menu_action_delete")
    /// 名前の変更
    internal static let tagListViewContextMenuActionUpdate = L10n.tr("Localizable", "tag_list_view_context_menu_action_update")
    /// はじめてのタグを追加する
    internal static let tagListViewEmptyActionTitle = L10n.tr("Localizable", "tag_list_view_empty_action_title")
    /// クリップをタグで分類すると、後から特定のタグに所属したクリップを一覧できます
    internal static let tagListViewEmptyMessage = L10n.tr("Localizable", "tag_list_view_empty_message")
    /// タグがありません
    internal static let tagListViewEmptyTitle = L10n.tr("Localizable", "tag_list_view_empty_title")
    /// タグ
    internal static let tagListViewTitle = L10n.tr("Localizable", "tag_list_view_title")
    /// タグを選択
    internal static let tagSelectionViewTitle = L10n.tr("Localizable", "tag_selection_view_title")
    /// 他のアプリの「共有」から、追加したい画像を含むサイトの URL をシェアしましょう
    internal static let topClipViewEmptyMessage = L10n.tr("Localizable", "top_clip_view_empty_message")
    /// クリップがありません
    internal static let topClipViewEmptyTitle = L10n.tr("Localizable", "top_clip_view_empty_title")
}

// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
    private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
        return String(format: format, locale: Locale.current, arguments: args)
    }
}

// swiftlint:disable convenience_type
private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #else
            return Bundle(for: BundleToken.self)
        #endif
    }()
}

// swiftlint:enable convenience_type
