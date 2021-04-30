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

    /// このアルバムの名前を入力してください
    internal static let albumListViewAlertForEditMessage = L10n.tr("Localizable", "album_list_view_alert_for_edit_message")
    /// アルバム名の編集
    internal static let albumListViewAlertForEditTitle = L10n.tr("Localizable", "album_list_view_alert_for_edit_title")
    /// 削除
    internal static let albumListViewContextMenuActionDelete = L10n.tr("Localizable", "album_list_view_context_menu_action_delete")
    /// 隠す
    internal static let albumListViewContextMenuActionHide = L10n.tr("Localizable", "album_list_view_context_menu_action_hide")
    /// 表示する
    internal static let albumListViewContextMenuActionReveal = L10n.tr("Localizable", "album_list_view_context_menu_action_reveal")
    /// タイトルの変更
    internal static let albumListViewContextMenuActionUpdate = L10n.tr("Localizable", "album_list_view_context_menu_action_update")
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
    /// アルバムタイトルの更新に失敗しました
    internal static let albumListViewErrorAtEditAlbum = L10n.tr("Localizable", "album_list_view_error_at_edit_album")
    /// アルバムの更新に失敗しました
    internal static let albumListViewErrorAtHideAlbum = L10n.tr("Localizable", "album_list_view_error_at_hide_album")
    /// アルバムの読み込みに失敗しました
    internal static let albumListViewErrorAtReadAlbums = L10n.tr("Localizable", "album_list_view_error_at_read_albums")
    /// 画像の読み込みに失敗しました
    internal static let albumListViewErrorAtReadImageData = L10n.tr("Localizable", "album_list_view_error_at_read_image_data")
    /// アルバムの並べ替えに失敗しました
    internal static let albumListViewErrorAtReorderAlbum = L10n.tr("Localizable", "album_list_view_error_at_reorder_album")
    /// アルバムの更新に失敗しました
    internal static let albumListViewErrorAtRevealAlbum = L10n.tr("Localizable", "album_list_view_error_at_reveal_album")
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
    /// 新しい画像を読み込んでいます\nしばらくお待ちください
    internal static let appRootLoadingMessage = L10n.tr("Localizable", "app_root_loading_message")
    /// (%d/%d)
    internal static func appRootLoadingProgress(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "app_root_loading_progress", p1, p2)
    }

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
    /// クリップの更新に失敗しました
    internal static let clipCollectionErrorAtRevealClip = L10n.tr("Localizable", "clip_collection_error_at_reveal_clip")
    /// クリップの更新に失敗しました
    internal static let clipCollectionErrorAtRevealClips = L10n.tr("Localizable", "clip_collection_error_at_reveal_clips")
    /// 共有に失敗しました
    internal static let clipCollectionErrorAtShare = L10n.tr("Localizable", "clip_collection_error_at_share")
    /// タグの更新に失敗しました
    internal static let clipCollectionErrorAtUpdateTagsToClip = L10n.tr("Localizable", "clip_collection_error_at_update_tags_to_clip")
    /// タグの更新に失敗しました
    internal static let clipCollectionErrorAtUpdateTagsToClips = L10n.tr("Localizable", "clip_collection_error_at_update_tags_to_clips")
    /// 全てのクリップ
    internal static let clipCollectionViewTitleAll = L10n.tr("Localizable", "clip_collection_view_title_all")
    /// クリップを選択
    internal static let clipCollectionViewTitleSelect = L10n.tr("Localizable", "clip_collection_view_title_select")
    /// %d件選択中
    internal static func clipCollectionViewTitleSelecting(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clip_collection_view_title_selecting", p1)
    }

    /// 画像を選択
    internal static let clipCreationViewTitle = L10n.tr("Localizable", "clip_creation_view_title")
    /// クリップに含まれる全ての画像も同時に削除されます
    internal static let clipEditViewAlertForDeleteClipMessage = L10n.tr("Localizable", "clip_edit_view_alert_for_delete_clip_message")
    /// クリップを削除
    internal static let clipEditViewAlertForDeleteClipTitle = L10n.tr("Localizable", "clip_edit_view_alert_for_delete_clip_title")
    /// 全体のサイズ
    internal static let clipEditViewClipDataSizeTitle = L10n.tr("Localizable", "clip_edit_view_clip_data_size_title")
    /// 削除
    internal static let clipEditViewDeleteClipItemTitle = L10n.tr("Localizable", "clip_edit_view_delete_clip_item_title")
    /// このクリップを削除
    internal static let clipEditViewDeleteClipTitle = L10n.tr("Localizable", "clip_edit_view_delete_clip_title")
    /// 隠す
    internal static let clipEditViewHiddenTitle = L10n.tr("Localizable", "clip_edit_view_hidden_title")
    /// キャンセル
    internal static let clipEditViewMultiselectCancel = L10n.tr("Localizable", "clip_edit_view_multiselect_cancel")
    /// サイトURLを編集
    internal static let clipEditViewMultiselectEditUrl = L10n.tr("Localizable", "clip_edit_view_multiselect_edit_url")
    /// 選択
    internal static let clipEditViewMultiselectSelect = L10n.tr("Localizable", "clip_edit_view_multiselect_select")
    /// クリップを編集
    internal static let clipEditViewTitle = L10n.tr("Localizable", "clip_edit_view_title")
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
    /// タグを追加する
    internal static let clipMergeViewAddTagTitle = L10n.tr("Localizable", "clip_merge_view_add_tag_title")
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
    internal static func clipsListAlertForChangeVisibilityRevealAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_change_visibility_reveal_action", p1)
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
    /// 別々のクリップに分割する
    internal static let clipsListAlertForPurgeAction = L10n.tr("Localizable", "clips_list_alert_for_purge_action")
    /// このクリップを削除し、含まれる画像1枚毎に新しいクリップを作成します\nタグやサイトURL、アルバムとの関連は維持されます
    internal static let clipsListAlertForPurgeMessage = L10n.tr("Localizable", "clips_list_alert_for_purge_message")
    /// この画像のみ共有する
    internal static let clipsListAlertForShareItemAction = L10n.tr("Localizable", "clips_list_alert_for_share_item_action")
    /// クリップ内の%d件の画像を共有する
    internal static func clipsListAlertForShareItemsAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_share_items_action", p1)
    }

    /// 追加
    internal static let clipsListContextMenuAdd = L10n.tr("Localizable", "clips_list_context_menu_add")
    /// タグを追加
    internal static let clipsListContextMenuAddTag = L10n.tr("Localizable", "clips_list_context_menu_add_tag")
    /// アルバムへ追加
    internal static let clipsListContextMenuAddToAlbum = L10n.tr("Localizable", "clips_list_context_menu_add_to_album")
    /// 削除
    internal static let clipsListContextMenuDelete = L10n.tr("Localizable", "clips_list_context_menu_delete")
    /// 編集
    internal static let clipsListContextMenuEdit = L10n.tr("Localizable", "clips_list_context_menu_edit")
    /// 隠す
    internal static let clipsListContextMenuHide = L10n.tr("Localizable", "clips_list_context_menu_hide")
    /// その他
    internal static let clipsListContextMenuOthers = L10n.tr("Localizable", "clips_list_context_menu_others")
    /// 分割
    internal static let clipsListContextMenuPurge = L10n.tr("Localizable", "clips_list_context_menu_purge")
    /// アルバムから削除
    internal static let clipsListContextMenuRemoveFromAlbum = L10n.tr("Localizable", "clips_list_context_menu_remove_from_album")
    /// 表示する
    internal static let clipsListContextMenuReveal = L10n.tr("Localizable", "clips_list_context_menu_reveal")
    /// 共有
    internal static let clipsListContextMenuShare = L10n.tr("Localizable", "clips_list_context_menu_share")
    /// 全て選択解除
    internal static let clipsListRightBarItemForDeselectAllTitle = L10n.tr("Localizable", "clips_list_right_bar_item_for_deselect_all_title")
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
    /// タグの更新に失敗しました
    internal static let errorTagDefault = L10n.tr("Localizable", "error_tag_default")
    /// タグの削除に失敗しました
    internal static let errorTagDelete = L10n.tr("Localizable", "error_tag_delete")
    /// タグの読み込みに失敗しました
    internal static let errorTagRead = L10n.tr("Localizable", "error_tag_read")
    /// 同じ名前のタグが既に存在します
    internal static let errorTagRenameDuplicated = L10n.tr("Localizable", "error_tag_rename_duplicated")
    /// クリップの削除に失敗しました
    internal static let failedToDeleteClip = L10n.tr("Localizable", "failed_to_delete_clip")
    /// クリップの更新に失敗しました
    internal static let failedToUpdateClip = L10n.tr("Localizable", "failed_to_update_clip")
    /// アルバム名
    internal static let placeholderAlbumName = L10n.tr("Localizable", "placeholder_album_name")
    /// アルバムを探す
    internal static let placeholderSearchAlbum = L10n.tr("Localizable", "placeholder_search_album")
    /// タグを探す
    internal static let placeholderSearchTag = L10n.tr("Localizable", "placeholder_search_tag")
    /// URL、タグ名、アルバム名...
    internal static let placeholderSearchUniversal = L10n.tr("Localizable", "placeholder_search_universal")
    /// タグ名
    internal static let placeholderTagName = L10n.tr("Localizable", "placeholder_tag_name")
    /// https://www...
    internal static let placeholderUrl = L10n.tr("Localizable", "placeholder_url")
    /// 非表示中
    internal static let searchEntryMenuDisplaySettingHidden = L10n.tr("Localizable", "search_entry_menu_display_setting_hidden")
    /// 表示中
    internal static let searchEntryMenuDisplaySettingRevealed = L10n.tr("Localizable", "search_entry_menu_display_setting_revealed")
    /// すべて
    internal static let searchEntryMenuDisplaySettingUnspecified = L10n.tr("Localizable", "search_entry_menu_display_setting_unspecified")
    /// 昇順
    internal static let searchEntryMenuSortAsc = L10n.tr("Localizable", "search_entry_menu_sort_asc")
    /// 作成日
    internal static let searchEntryMenuSortCreatedDate = L10n.tr("Localizable", "search_entry_menu_sort_created_date")
    /// サイズ
    internal static let searchEntryMenuSortDataSize = L10n.tr("Localizable", "search_entry_menu_sort_data_size")
    /// 降順
    internal static let searchEntryMenuSortDesc = L10n.tr("Localizable", "search_entry_menu_sort_desc")
    /// 更新日
    internal static let searchEntryMenuSortUpdatedDate = L10n.tr("Localizable", "search_entry_menu_sort_updated_date")
    /// 検索に失敗しました
    internal static let searchEntryViewErrorAtSearch = L10n.tr("Localizable", "search_entry_view_error_at_search")
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
    /// "%@"の検索結果はありませんでした。新しい検索を試してください。
    internal static func searchResultNotFoundMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "search_result_not_found_message", String(describing: p1))
    }

    /// 結果なし
    internal static let searchResultNotFoundTitle = L10n.tr("Localizable", "search_result_not_found_title")
    /// すべて見る
    internal static let searchResultSeeAllButton = L10n.tr("Localizable", "search_result_see_all_button")
    /// 未分類
    internal static let searchResultTitleUncategorized = L10n.tr("Localizable", "search_result_title_uncategorized")
    /// 設定
    internal static let settingViewTitle = L10n.tr("Localizable", "setting_view_title")
    /// この端末に保存したデータを他のiOS/iPadOS端末と共有できなくなります。同期がオフの最中に保存したデータは、後ほどiCloud同期が有効になった際に、他のiOS/iPadOS端末のデータと統合されます
    internal static let settingsConfirmIcloudSyncOffMessage = L10n.tr("Localizable", "settings_confirm_icloud_sync_off_message")
    /// iCloud同期をオフにしますか？
    internal static let settingsConfirmIcloudSyncOffTitle = L10n.tr("Localizable", "settings_confirm_icloud_sync_off_title")
    /// このタグの名前を入力してください
    internal static let tagListViewAlertForAddMessage = L10n.tr("Localizable", "tag_list_view_alert_for_add_message")
    /// 新規タグ
    internal static let tagListViewAlertForAddTitle = L10n.tr("Localizable", "tag_list_view_alert_for_add_title")
    /// タグを削除
    internal static let tagListViewAlertForDeleteAction = L10n.tr("Localizable", "tag_list_view_alert_for_delete_action")
    /// タグ「%@」を削除しますか？\n含まれるクリップは削除されません
    internal static func tagListViewAlertForDeleteMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "tag_list_view_alert_for_delete_message", String(describing: p1))
    }

    /// このタグの新しい名前を入力してください
    internal static let tagListViewAlertForUpdateMessage = L10n.tr("Localizable", "tag_list_view_alert_for_update_message")
    /// タグ名の変更
    internal static let tagListViewAlertForUpdateTitle = L10n.tr("Localizable", "tag_list_view_alert_for_update_title")
    /// コピー
    internal static let tagListViewContextMenuActionCopy = L10n.tr("Localizable", "tag_list_view_context_menu_action_copy")
    /// 削除
    internal static let tagListViewContextMenuActionDelete = L10n.tr("Localizable", "tag_list_view_context_menu_action_delete")
    /// 隠す
    internal static let tagListViewContextMenuActionHide = L10n.tr("Localizable", "tag_list_view_context_menu_action_hide")
    /// 表示する
    internal static let tagListViewContextMenuActionReveal = L10n.tr("Localizable", "tag_list_view_context_menu_action_reveal")
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
    /// コピー
    internal static let urlContextMenuCopy = L10n.tr("Localizable", "url_context_menu_copy")
    /// 開く
    internal static let urlContextMenuOpen = L10n.tr("Localizable", "url_context_menu_open")
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
