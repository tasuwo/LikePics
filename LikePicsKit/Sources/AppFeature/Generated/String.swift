// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
enum L10n {
    /// このアルバムの名前を入力してください
    static let albumListViewAlertForAddMessage = L10n.tr("Localizable", "album_list_view_alert_for_add_message")
    /// 新規アルバム
    static let albumListViewAlertForAddTitle = L10n.tr("Localizable", "album_list_view_alert_for_add_title")
    /// アルバムを削除
    static let albumListViewAlertForDeleteAction = L10n.tr("Localizable", "album_list_view_alert_for_delete_action")
    /// アルバム"%@"を削除しますか？
    /// 含まれるクリップは削除されません
    static func albumListViewAlertForDeleteMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "album_list_view_alert_for_delete_message", String(describing: p1))
    }

    /// "%@"を削除
    static func albumListViewAlertForDeleteTitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "album_list_view_alert_for_delete_title", String(describing: p1))
    }

    /// このアルバムの名前を入力してください
    static let albumListViewAlertForEditMessage = L10n.tr("Localizable", "album_list_view_alert_for_edit_message")
    /// アルバム名の編集
    static let albumListViewAlertForEditTitle = L10n.tr("Localizable", "album_list_view_alert_for_edit_title")
    /// 削除
    static let albumListViewContextMenuActionDelete = L10n.tr("Localizable", "album_list_view_context_menu_action_delete")
    /// 隠す
    static let albumListViewContextMenuActionHide = L10n.tr("Localizable", "album_list_view_context_menu_action_hide")
    /// 表示する
    static let albumListViewContextMenuActionReveal = L10n.tr("Localizable", "album_list_view_context_menu_action_reveal")
    /// タイトルの変更
    static let albumListViewContextMenuActionUpdate = L10n.tr("Localizable", "album_list_view_context_menu_action_update")
    /// はじめてのアルバムを追加する
    static let albumListViewEmptyActionTitle = L10n.tr("Localizable", "album_list_view_empty_action_title")
    /// 複数のクリップをアルバムにまとめることができます
    static let albumListViewEmptyMessage = L10n.tr("Localizable", "album_list_view_empty_message")
    /// アルバムがありません
    static let albumListViewEmptyTitle = L10n.tr("Localizable", "album_list_view_empty_title")
    /// アルバムの追加に失敗しました
    static let albumListViewErrorAtAddAlbum = L10n.tr("Localizable", "album_list_view_error_at_add_album")
    /// アルバムの削除に失敗しました
    static let albumListViewErrorAtDeleteAlbum = L10n.tr("Localizable", "album_list_view_error_at_delete_album")
    /// アルバムタイトルの更新に失敗しました
    static let albumListViewErrorAtEditAlbum = L10n.tr("Localizable", "album_list_view_error_at_edit_album")
    /// アルバムの更新に失敗しました
    static let albumListViewErrorAtHideAlbum = L10n.tr("Localizable", "album_list_view_error_at_hide_album")
    /// アルバムの読み込みに失敗しました
    static let albumListViewErrorAtReadAlbums = L10n.tr("Localizable", "album_list_view_error_at_read_albums")
    /// 画像の読み込みに失敗しました
    static let albumListViewErrorAtReadImageData = L10n.tr("Localizable", "album_list_view_error_at_read_image_data")
    /// アルバムの並べ替えに失敗しました
    static let albumListViewErrorAtReorderAlbum = L10n.tr("Localizable", "album_list_view_error_at_reorder_album")
    /// アルバムの更新に失敗しました
    static let albumListViewErrorAtRevealAlbum = L10n.tr("Localizable", "album_list_view_error_at_reveal_album")
    /// アルバム
    static let albumListViewTitle = L10n.tr("Localizable", "album_list_view_title")
    /// はじめてのアルバムを追加する
    static let albumSelectionViewEmptyActionTitle = L10n.tr("Localizable", "album_selection_view_empty_action_title")
    /// 複数のクリップをアルバムにまとめることができます
    static let albumSelectionViewEmptyMessage = L10n.tr("Localizable", "album_selection_view_empty_message")
    /// アルバムがありません
    static let albumSelectionViewEmptyTitle = L10n.tr("Localizable", "album_selection_view_empty_title")
    /// アルバムへ追加
    static let albumSelectionViewTitle = L10n.tr("Localizable", "album_selection_view_title")
    /// アルバム内にクリップがありません
    static let albumViewEmptyTitle = L10n.tr("Localizable", "album_view_empty_title")
    /// %d件の画像を削除
    static func alertForDeleteClipItemsAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "alert_for_delete_clip_items_action", p1)
    }

    /// 選択した画像を完全に削除します
    static let alertForDeleteClipItemsMessage = L10n.tr("Localizable", "alert_for_delete_clip_items_message")
    /// 選択した画像の保存元のサイトのURLを更新します
    /// 元の設定は上書きされます
    static let alertForEditClipItemsSiteUrlMessage = L10n.tr("Localizable", "alert_for_edit_clip_items_site_url_message")
    /// この画像の保存元のサイトのURLを入力してください
    static let alertForEditSiteUrlMessage = L10n.tr("Localizable", "alert_for_edit_site_url_message")
    /// サイトのURL
    static let alertForEditSiteUrlTitle = L10n.tr("Localizable", "alert_for_edit_site_url_title")
    /// 新しい画像を読み込んでいます
    /// しばらくお待ちください
    static let appRootLoadingMessage = L10n.tr("Localizable", "app_root_loading_message")
    /// (%d/%d)
    static func appRootLoadingProgress(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "app_root_loading_progress", p1, p2)
    }

    /// アルバム
    static let appRootTabItemAlbum = L10n.tr("Localizable", "app_root_tab_item_album")
    /// ホーム
    static let appRootTabItemHome = L10n.tr("Localizable", "app_root_tab_item_home")
    /// 検索
    static let appRootTabItemSearch = L10n.tr("Localizable", "app_root_tab_item_search")
    /// 設定
    static let appRootTabItemSettings = L10n.tr("Localizable", "app_root_tab_item_settings")
    /// タグ
    static let appRootTabItemTag = L10n.tr("Localizable", "app_root_tab_item_tag")
    /// キャンセル
    static let barItemForCancel = L10n.tr("Localizable", "bar_item_for_cancel")
    /// 全て選択解除
    static let barItemForDeselectAllTitle = L10n.tr("Localizable", "bar_item_for_deselect_all_title")
    /// 再開
    static let barItemForResume = L10n.tr("Localizable", "bar_item_for_resume")
    /// 全て選択
    static let barItemForSelectAllTitle = L10n.tr("Localizable", "bar_item_for_select_all_title")
    /// 選択
    static let barItemForSelectTitle = L10n.tr("Localizable", "bar_item_for_select_title")
    /// アルバムへの追加に失敗しました
    static let clipCollectionErrorAtAddClipToAlbum = L10n.tr("Localizable", "clip_collection_error_at_add_clip_to_album")
    /// アルバムへの追加に失敗しました
    static let clipCollectionErrorAtAddClipsToAlbum = L10n.tr("Localizable", "clip_collection_error_at_add_clips_to_album")
    /// すでにアルバムに追加済みです
    static let clipCollectionErrorAtAddClipsToAlbumDuplicated = L10n.tr("Localizable", "clip_collection_error_at_add_clips_to_album_duplicated")
    /// クリップの削除に失敗しました
    static let clipCollectionErrorAtDeleteClip = L10n.tr("Localizable", "clip_collection_error_at_delete_clip")
    /// クリップの削除に失敗しました
    static let clipCollectionErrorAtDeleteClips = L10n.tr("Localizable", "clip_collection_error_at_delete_clips")
    /// 読み込みに失敗しました
    static let clipCollectionErrorAtDuplicates = L10n.tr("Localizable", "clip_collection_error_at_duplicates")
    /// クリップの更新に失敗しました
    static let clipCollectionErrorAtHideClip = L10n.tr("Localizable", "clip_collection_error_at_hide_clip")
    /// クリップの更新に失敗しました
    static let clipCollectionErrorAtHideClips = L10n.tr("Localizable", "clip_collection_error_at_hide_clips")
    /// クリップの分割に失敗しました
    static let clipCollectionErrorAtPurge = L10n.tr("Localizable", "clip_collection_error_at_purge")
    /// アルバムからの削除に失敗しました
    static let clipCollectionErrorAtRemoveClipsFromAlbum = L10n.tr("Localizable", "clip_collection_error_at_remove_clips_from_album")
    /// クリップ内の画像の削除に失敗しました
    static let clipCollectionErrorAtRemoveItemFromClip = L10n.tr("Localizable", "clip_collection_error_at_remove_item_from_clip")
    /// 並び替えに失敗しました
    static let clipCollectionErrorAtReorder = L10n.tr("Localizable", "clip_collection_error_at_reorder")
    /// クリップの更新に失敗しました
    static let clipCollectionErrorAtRevealClip = L10n.tr("Localizable", "clip_collection_error_at_reveal_clip")
    /// クリップの更新に失敗しました
    static let clipCollectionErrorAtRevealClips = L10n.tr("Localizable", "clip_collection_error_at_reveal_clips")
    /// 共有に失敗しました
    static let clipCollectionErrorAtShare = L10n.tr("Localizable", "clip_collection_error_at_share")
    /// タグの更新に失敗しました
    static let clipCollectionErrorAtUpdateTagsToClip = L10n.tr("Localizable", "clip_collection_error_at_update_tags_to_clip")
    /// タグの更新に失敗しました
    static let clipCollectionErrorAtUpdateTagsToClips = L10n.tr("Localizable", "clip_collection_error_at_update_tags_to_clips")
    /// 全てのクリップ
    static let clipCollectionViewTitleAll = L10n.tr("Localizable", "clip_collection_view_title_all")
    /// クリップを選択
    static let clipCollectionViewTitleSelect = L10n.tr("Localizable", "clip_collection_view_title_select")
    /// %d件選択中
    static func clipCollectionViewTitleSelecting(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clip_collection_view_title_selecting", p1)
    }

    /// 画像を選択
    static let clipCreationViewTitle = L10n.tr("Localizable", "clip_creation_view_title")
    /// クリップに含まれる全ての画像も同時に削除されます
    static let clipEditViewAlertForDeleteClipMessage = L10n.tr("Localizable", "clip_edit_view_alert_for_delete_clip_message")
    /// クリップを削除
    static let clipEditViewAlertForDeleteClipTitle = L10n.tr("Localizable", "clip_edit_view_alert_for_delete_clip_title")
    /// 全体のサイズ
    static let clipEditViewClipDataSizeTitle = L10n.tr("Localizable", "clip_edit_view_clip_data_size_title")
    /// 削除
    static let clipEditViewDeleteClipItemTitle = L10n.tr("Localizable", "clip_edit_view_delete_clip_item_title")
    /// このクリップを削除
    static let clipEditViewDeleteClipTitle = L10n.tr("Localizable", "clip_edit_view_delete_clip_title")
    /// 隠す
    static let clipEditViewHiddenTitle = L10n.tr("Localizable", "clip_edit_view_hidden_title")
    /// キャンセル
    static let clipEditViewMultiselectCancel = L10n.tr("Localizable", "clip_edit_view_multiselect_cancel")
    /// サイトURLを編集
    static let clipEditViewMultiselectEditUrl = L10n.tr("Localizable", "clip_edit_view_multiselect_edit_url")
    /// 選択
    static let clipEditViewMultiselectSelect = L10n.tr("Localizable", "clip_edit_view_multiselect_select")
    /// クリップを編集
    static let clipEditViewTitle = L10n.tr("Localizable", "clip_edit_view_title")
    /// 削除
    static let clipInformationAlertForDeleteAction = L10n.tr("Localizable", "clip_information_alert_for_delete_action")
    /// 画像のURLをコピー
    static let clipInformationContextMenuCopyImageUrl = L10n.tr("Localizable", "clip_information_context_menu_copy_image_url")
    /// 削除
    static let clipInformationContextMenuDelete = L10n.tr("Localizable", "clip_information_context_menu_delete")
    /// 画像のURLを開く
    static let clipInformationContextMenuOpenImageUrl = L10n.tr("Localizable", "clip_information_context_menu_open_image_url")
    /// 画像の読み込みに失敗しました
    static let clipInformationErrorAtReadClip = L10n.tr("Localizable", "clip_information_error_at_read_clip")
    /// タグの削除に失敗しました
    static let clipInformationErrorAtRemoveTags = L10n.tr("Localizable", "clip_information_error_at_remove_tags")
    /// タグの更新に失敗しました
    static let clipInformationErrorAtReplaceTags = L10n.tr("Localizable", "clip_information_error_at_replace_tags")
    /// 更新に失敗しました
    static let clipInformationErrorAtUpdateHidden = L10n.tr("Localizable", "clip_information_error_at_update_hidden")
    /// URLの更新に失敗しました
    static let clipInformationErrorAtUpdateSiteUrl = L10n.tr("Localizable", "clip_information_error_at_update_site_url")
    /// 戻る
    static let clipInformationKeyCommandDown = L10n.tr("Localizable", "clip_information_key_command_down")
    /// 削除
    static let clipInformationViewAlertForDeleteTagAction = L10n.tr("Localizable", "clip_information_view_alert_for_delete_tag_action")
    /// このタグを削除しますか？
    /// クリップ及び画像は削除されません
    static let clipInformationViewAlertForDeleteTagMessage = L10n.tr("Localizable", "clip_information_view_alert_for_delete_tag_message")
    /// 無題
    static let clipItemCellNoTitle = L10n.tr("Localizable", "clip_item_cell_no_title")
    /// タグを追加する
    static let clipMergeViewAddTagTitle = L10n.tr("Localizable", "clip_merge_view_add_tag_title")
    /// 保存する画像の取得元となるサイトURLを上書きできます
    /// サイトURLは全ての画像に適用されます
    static let clipMergeViewAlertForAddUrlMessage = L10n.tr("Localizable", "clip_merge_view_alert_for_add_url_message")
    /// サイトURLを上書き
    static let clipMergeViewAlertForAddUrlTitle = L10n.tr("Localizable", "clip_merge_view_alert_for_add_url_title")
    /// 保存する画像の取得元となるサイトURLを編集します
    /// サイトURLは全ての画像に適用されます
    static let clipMergeViewAlertForEditUrlMessage = L10n.tr("Localizable", "clip_merge_view_alert_for_edit_url_message")
    /// サイトURLを編集
    static let clipMergeViewAlertForEditUrlTitle = L10n.tr("Localizable", "clip_merge_view_alert_for_edit_url_title")
    /// https://...
    static let clipMergeViewAlertForUrlPlaceholder = L10n.tr("Localizable", "clip_merge_view_alert_for_url_placeholder")
    /// 保存に失敗しました
    static let clipMergeViewErrorAtMerge = L10n.tr("Localizable", "clip_merge_view_error_at_merge")
    /// 保存した画像を隠す
    static let clipMergeViewMetaShouldHides = L10n.tr("Localizable", "clip_merge_view_meta_should_hides")
    /// 編集
    static let clipMergeViewMetaUrlEdit = L10n.tr("Localizable", "clip_merge_view_meta_url_edit")
    /// サイトURLの上書きなし
    static let clipMergeViewMetaUrlNo = L10n.tr("Localizable", "clip_merge_view_meta_url_no")
    /// 上書き
    static let clipMergeViewMetaUrlOverwrite = L10n.tr("Localizable", "clip_merge_view_meta_url_overwrite")
    /// サイトURL
    static let clipMergeViewMetaUrlTitle = L10n.tr("Localizable", "clip_merge_view_meta_url_title")
    /// 画像をクリップにまとめる
    static let clipMergeViewTitle = L10n.tr("Localizable", "clip_merge_view_title")
    /// 画像の読み込みに失敗しました
    static let clipPreviewErrorAtLoadImage = L10n.tr("Localizable", "clip_preview_error_at_load_image")
    /// クリップの読み込みに失敗しました
    static let clipPreviewPageViewErrorAtReadClip = L10n.tr("Localizable", "clip_preview_page_view_error_at_read_clip")
    /// タグを追加する
    static let clipPreviewViewAlertForAddTag = L10n.tr("Localizable", "clip_preview_view_alert_for_add_tag")
    /// アルバムに追加する
    static let clipPreviewViewAlertForAddToAlbum = L10n.tr("Localizable", "clip_preview_view_alert_for_add_to_album")
    /// クリップを削除する
    static let clipPreviewViewAlertForDeleteClipAction = L10n.tr("Localizable", "clip_preview_view_alert_for_delete_clip_action")
    /// 画像を削除する
    static let clipPreviewViewAlertForDeleteClipItemAction = L10n.tr("Localizable", "clip_preview_view_alert_for_delete_clip_item_action")
    /// クリップを削除すると、このクリップに含まれる全ての画像も同時に削除されます
    static let clipPreviewViewAlertForDeleteMessage = L10n.tr("Localizable", "clip_preview_view_alert_for_delete_message")
    /// 隠す
    static let clipPreviewViewAlertForHideAction = L10n.tr("Localizable", "clip_preview_view_alert_for_hide_action")
    /// このクリップは、設定が有効な間は全ての場所から隠されます
    static let clipPreviewViewAlertForHideMessage = L10n.tr("Localizable", "clip_preview_view_alert_for_hide_message")
    /// 正常に削除しました
    static let clipPreviewViewAlertForSuccessfullyDeleteMessage = L10n.tr("Localizable", "clip_preview_view_alert_for_successfully_delete_message")
    /// 画像の読み込みに失敗しました。クリップしなおしてください
    static let clipPreviewViewErrorAtReadImage = L10n.tr("Localizable", "clip_preview_view_error_at_read_image")
    /// タグを追加する
    static let clipsListAlertForAddTag = L10n.tr("Localizable", "clips_list_alert_for_add_tag")
    /// アルバムに追加する
    static let clipsListAlertForAddToAlbum = L10n.tr("Localizable", "clips_list_alert_for_add_to_album")
    /// %d件のクリップを隠す
    static func clipsListAlertForChangeVisibilityHideAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_change_visibility_hide_action", p1)
    }

    /// 隠したクリップは、設定が有効な間は全ての場所から隠されます
    static let clipsListAlertForChangeVisibilityMessage = L10n.tr("Localizable", "clips_list_alert_for_change_visibility_message")
    /// %d件のクリップを表示する
    static func clipsListAlertForChangeVisibilityRevealAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_change_visibility_reveal_action", p1)
    }

    /// %d件のクリップを削除
    static func clipsListAlertForDeleteAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_delete_action", p1)
    }

    /// 削除
    static let clipsListAlertForDeleteInAlbumActionDelete = L10n.tr("Localizable", "clips_list_alert_for_delete_in_album_action_delete")
    /// アルバムから削除
    static let clipsListAlertForDeleteInAlbumActionRemoveFromAlbum = L10n.tr("Localizable", "clips_list_alert_for_delete_in_album_action_remove_from_album")
    /// これらのクリップを削除、あるいはアルバムから削除しますか？
    static let clipsListAlertForDeleteInAlbumMessage = L10n.tr("Localizable", "clips_list_alert_for_delete_in_album_message")
    /// クリップを削除すると、クリップに含まれる全ての画像も同時に削除されます
    static let clipsListAlertForDeleteMessage = L10n.tr("Localizable", "clips_list_alert_for_delete_message")
    /// 別々のクリップに分割する
    static let clipsListAlertForPurgeAction = L10n.tr("Localizable", "clips_list_alert_for_purge_action")
    /// このクリップを削除し、含まれる画像1枚毎に新しいクリップを作成します
    /// タグやサイトURL、アルバムとの関連は維持されます
    static let clipsListAlertForPurgeMessage = L10n.tr("Localizable", "clips_list_alert_for_purge_message")
    /// %d件のクリップを取り除く
    static func clipsListAlertForRemoveFromAlbumAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_remove_from_album_action", p1)
    }

    /// クリップをアルバムから取り除きますか？クリップ自体や含まれる画像は削除されません
    static let clipsListAlertForRemoveFromAlbumMessage = L10n.tr("Localizable", "clips_list_alert_for_remove_from_album_message")
    /// この画像のみ共有する
    static let clipsListAlertForShareItemAction = L10n.tr("Localizable", "clips_list_alert_for_share_item_action")
    /// クリップ内の%d件の画像を共有する
    static func clipsListAlertForShareItemsAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_share_items_action", p1)
    }

    /// 追加
    static let clipsListContextMenuAdd = L10n.tr("Localizable", "clips_list_context_menu_add")
    /// タグを追加
    static let clipsListContextMenuAddTag = L10n.tr("Localizable", "clips_list_context_menu_add_tag")
    /// アルバムへ追加
    static let clipsListContextMenuAddToAlbum = L10n.tr("Localizable", "clips_list_context_menu_add_to_album")
    /// 削除
    static let clipsListContextMenuDelete = L10n.tr("Localizable", "clips_list_context_menu_delete")
    /// 隠す
    static let clipsListContextMenuHide = L10n.tr("Localizable", "clips_list_context_menu_hide")
    /// その他
    static let clipsListContextMenuOthers = L10n.tr("Localizable", "clips_list_context_menu_others")
    /// 分割
    static let clipsListContextMenuPurge = L10n.tr("Localizable", "clips_list_context_menu_purge")
    /// アルバムから削除
    static let clipsListContextMenuRemoveFromAlbum = L10n.tr("Localizable", "clips_list_context_menu_remove_from_album")
    /// 表示する
    static let clipsListContextMenuReveal = L10n.tr("Localizable", "clips_list_context_menu_reveal")
    /// 共有
    static let clipsListContextMenuShare = L10n.tr("Localizable", "clips_list_context_menu_share")
    /// キャンセル
    static let confirmAlertCancel = L10n.tr("Localizable", "confirm_alert_cancel")
    /// OK
    static let confirmAlertOk = L10n.tr("Localizable", "confirm_alert_ok")
    /// 保存
    static let confirmAlertSave = L10n.tr("Localizable", "confirm_alert_save")
    /// 画像の削除に失敗しました
    static let errorAtDeleteClipItem = L10n.tr("Localizable", "error_at_delete_clip_item")
    /// 更新に失敗しました
    static let errorAtUpdateSiteUrlClipItem = L10n.tr("Localizable", "error_at_update_site_url_clip_item")
    /// しばらく時間を置いてから再度お試しください
    static let errorIcloudDefaultMessage = L10n.tr("Localizable", "error_icloud_default_message")
    /// iCloudが利用できません
    static let errorIcloudDefaultTitle = L10n.tr("Localizable", "error_icloud_default_title")
    /// iCloudは現在利用できません
    static let errorIcloudFailureMessage = L10n.tr("Localizable", "error_icloud_failure_message")
    /// iCloudが利用できません
    static let errorIcloudFailureTitle = L10n.tr("Localizable", "error_icloud_failure_title")
    /// 二度と表示しない
    static let errorIcloudIgnoreAction = L10n.tr("Localizable", "error_icloud_ignore_action")
    /// iCloudアカウントでログインしていないか、端末のiCloud同期設定がオフになっている可能性があります。
    /// iCluoudが利用できない間に保存したデータは、後ほどiCloudが有効になった際に統合されます
    static let errorIcloudUnavailableMessage = L10n.tr("Localizable", "error_icloud_unavailable_message")
    /// iCloudが利用できません
    static let errorIcloudUnavailableTitle = L10n.tr("Localizable", "error_icloud_unavailable_title")
    /// iCloud同期を利用しない
    static let errorIcloudUnavailableTurnOffAction = L10n.tr("Localizable", "error_icloud_unavailable_turn_off_action")
    /// iCloud同期を自動で有効にする
    static let errorIcloudUnavailableTurnOnAction = L10n.tr("Localizable", "error_icloud_unavailable_turn_on_action")
    /// タグの追加に失敗しました
    static let errorTagAddDefault = L10n.tr("Localizable", "error_tag_add_default")
    /// 同名のタグを追加することはできません
    static let errorTagAddDuplicated = L10n.tr("Localizable", "error_tag_add_duplicated")
    /// タグの更新に失敗しました
    static let errorTagDefault = L10n.tr("Localizable", "error_tag_default")
    /// タグの削除に失敗しました
    static let errorTagDelete = L10n.tr("Localizable", "error_tag_delete")
    /// タグの読み込みに失敗しました
    static let errorTagRead = L10n.tr("Localizable", "error_tag_read")
    /// 同じ名前のタグが既に存在します
    static let errorTagRenameDuplicated = L10n.tr("Localizable", "error_tag_rename_duplicated")
    /// クリップの削除に失敗しました
    static let failedToDeleteClip = L10n.tr("Localizable", "failed_to_delete_clip")
    /// クリップの更新に失敗しました
    static let failedToUpdateClip = L10n.tr("Localizable", "failed_to_update_clip")
    /// アルバム名
    static let placeholderAlbumName = L10n.tr("Localizable", "placeholder_album_name")
    /// アルバムを探す
    static let placeholderSearchAlbum = L10n.tr("Localizable", "placeholder_search_album")
    /// タグを探す
    static let placeholderSearchTag = L10n.tr("Localizable", "placeholder_search_tag")
    /// URL、タグ名、アルバム名...
    static let placeholderSearchUniversal = L10n.tr("Localizable", "placeholder_search_universal")
    /// タグ名
    static let placeholderTagName = L10n.tr("Localizable", "placeholder_tag_name")
    /// https://www...
    static let placeholderUrl = L10n.tr("Localizable", "placeholder_url")
    /// 非表示中
    static let searchEntryMenuDisplaySettingHidden = L10n.tr("Localizable", "search_entry_menu_display_setting_hidden")
    /// 表示中
    static let searchEntryMenuDisplaySettingRevealed = L10n.tr("Localizable", "search_entry_menu_display_setting_revealed")
    /// すべて
    static let searchEntryMenuDisplaySettingUnspecified = L10n.tr("Localizable", "search_entry_menu_display_setting_unspecified")
    /// 昇順
    static let searchEntryMenuSortAsc = L10n.tr("Localizable", "search_entry_menu_sort_asc")
    /// 作成日
    static let searchEntryMenuSortCreatedDate = L10n.tr("Localizable", "search_entry_menu_sort_created_date")
    /// サイズ
    static let searchEntryMenuSortDataSize = L10n.tr("Localizable", "search_entry_menu_sort_data_size")
    /// 降順
    static let searchEntryMenuSortDesc = L10n.tr("Localizable", "search_entry_menu_sort_desc")
    /// 更新日
    static let searchEntryMenuSortUpdatedDate = L10n.tr("Localizable", "search_entry_menu_sort_updated_date")
    /// 検索に失敗しました
    static let searchEntryViewErrorAtSearch = L10n.tr("Localizable", "search_entry_view_error_at_search")
    /// 検索
    static let searchEntryViewTitle = L10n.tr("Localizable", "search_entry_view_title")
    /// 削除
    static let searchHistoryDeleteAction = L10n.tr("Localizable", "search_history_delete_action")
    /// 履歴は最大100件まで保持されます。100件より多い場合、古い履歴から順に削除されます
    static let searchHistoryFooterMessage = L10n.tr("Localizable", "search_history_footer_message")
    /// 削除
    static let searchHistoryRemoveAllConfirmationAction = L10n.tr("Localizable", "search_history_remove_all_confirmation_action")
    /// すべての検索履歴を削除します
    static let searchHistoryRemoveAllConfirmationMessage = L10n.tr("Localizable", "search_history_remove_all_confirmation_message")
    /// 最近の検索はありません
    static let searchHistoryRowEmptyMessage = L10n.tr("Localizable", "search_history_row_empty_message")
    /// キーワード「%@」に一致するクリップは見つかりませんでした
    static func searchResultForKeywordsEmptyTitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "search_result_for_keywords_empty_title", String(describing: p1))
    }

    /// タグ「%@」が付与されたクリップはありません
    static func searchResultForTagEmptyTitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "search_result_for_tag_empty_title", String(describing: p1))
    }

    /// 未分類のクリップはありません
    static let searchResultForUncategorizedEmptyTitle = L10n.tr("Localizable", "search_result_for_uncategorized_empty_title")
    /// "%@"の検索結果はありませんでした。新しい検索を試してください。
    static func searchResultNotFoundMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "search_result_not_found_message", String(describing: p1))
    }

    /// 結果なし
    static let searchResultNotFoundTitle = L10n.tr("Localizable", "search_result_not_found_title")
    /// すべて見る
    static let searchResultSeeAllButton = L10n.tr("Localizable", "search_result_see_all_button")
    /// 未分類
    static let searchResultTitleUncategorized = L10n.tr("Localizable", "search_result_title_uncategorized")
    /// 設定
    static let settingViewTitle = L10n.tr("Localizable", "setting_view_title")
    /// データ使用量を空けるために、サムネイルのキャッシュデータを全て削除します。キャッシュは必要に応じて自動的に再生成されます
    static let settingsConfirmClearCacheMessage = L10n.tr("Localizable", "settings_confirm_clear_cache_message")
    /// サムネイルのキャッシュを削除
    static let settingsConfirmClearCacheTitle = L10n.tr("Localizable", "settings_confirm_clear_cache_title")
    /// この端末に保存したデータを他のiOS/iPadOS端末と共有できなくなります。同期がオフの最中に保存したデータは、後ほどiCloud同期が有効になった際に、他のiOS/iPadOS端末のデータと統合されます
    static let settingsConfirmIcloudSyncOffMessage = L10n.tr("Localizable", "settings_confirm_icloud_sync_off_message")
    /// iCloud同期をオフにしますか？
    static let settingsConfirmIcloudSyncOffTitle = L10n.tr("Localizable", "settings_confirm_icloud_sync_off_title")
    /// ダーク
    static let settingsInterfaceStyleDark = L10n.tr("Localizable", "settings_interface_style_dark")
    /// ライト
    static let settingsInterfaceStyleLight = L10n.tr("Localizable", "settings_interface_style_light")
    /// 端末に合わせる
    static let settingsInterfaceStyleUnspecified = L10n.tr("Localizable", "settings_interface_style_unspecified")
    /// このタグの名前を入力してください
    static let tagListViewAlertForAddMessage = L10n.tr("Localizable", "tag_list_view_alert_for_add_message")
    /// 新規タグ
    static let tagListViewAlertForAddTitle = L10n.tr("Localizable", "tag_list_view_alert_for_add_title")
    /// タグを削除
    static let tagListViewAlertForDeleteAction = L10n.tr("Localizable", "tag_list_view_alert_for_delete_action")
    /// タグ「%@」を削除しますか？
    /// 含まれるクリップは削除されません
    static func tagListViewAlertForDeleteMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "tag_list_view_alert_for_delete_message", String(describing: p1))
    }

    /// このタグの新しい名前を入力してください
    static let tagListViewAlertForUpdateMessage = L10n.tr("Localizable", "tag_list_view_alert_for_update_message")
    /// タグ名の変更
    static let tagListViewAlertForUpdateTitle = L10n.tr("Localizable", "tag_list_view_alert_for_update_title")
    /// コピー
    static let tagListViewContextMenuActionCopy = L10n.tr("Localizable", "tag_list_view_context_menu_action_copy")
    /// 削除
    static let tagListViewContextMenuActionDelete = L10n.tr("Localizable", "tag_list_view_context_menu_action_delete")
    /// 隠す
    static let tagListViewContextMenuActionHide = L10n.tr("Localizable", "tag_list_view_context_menu_action_hide")
    /// 表示する
    static let tagListViewContextMenuActionReveal = L10n.tr("Localizable", "tag_list_view_context_menu_action_reveal")
    /// 名前の変更
    static let tagListViewContextMenuActionUpdate = L10n.tr("Localizable", "tag_list_view_context_menu_action_update")
    /// はじめてのタグを追加する
    static let tagListViewEmptyActionTitle = L10n.tr("Localizable", "tag_list_view_empty_action_title")
    /// クリップをタグで分類すると、後から特定のタグに所属したクリップを一覧できます
    static let tagListViewEmptyMessage = L10n.tr("Localizable", "tag_list_view_empty_message")
    /// タグがありません
    static let tagListViewEmptyTitle = L10n.tr("Localizable", "tag_list_view_empty_title")
    /// タグ
    static let tagListViewTitle = L10n.tr("Localizable", "tag_list_view_title")
    /// タグを選択
    static let tagSelectionViewTitle = L10n.tr("Localizable", "tag_selection_view_title")
    /// 他のアプリの「共有」から、追加したい画像を含むサイトの URL をシェアしましょう
    static let topClipViewEmptyMessage = L10n.tr("Localizable", "top_clip_view_empty_message")
    /// クリップがありません
    static let topClipViewEmptyTitle = L10n.tr("Localizable", "top_clip_view_empty_title")
    /// コピー
    static let urlContextMenuCopy = L10n.tr("Localizable", "url_context_menu_copy")
    /// 開く
    static let urlContextMenuOpen = L10n.tr("Localizable", "url_context_menu_open")

    enum ClipPreview {
        enum KeyCommand {
            /// 戻る
            static let back = L10n.tr("Localizable", "clip_preview.key_command.back")
            /// 前のアイテムへ移動
            static let backward = L10n.tr("Localizable", "clip_preview.key_command.backward")
            /// 詳細情報を見る
            static let detail = L10n.tr("Localizable", "clip_preview.key_command.detail")
            /// 次のアイテムへ移動
            static let forward = L10n.tr("Localizable", "clip_preview.key_command.forward")
        }

        enum OptionMenuItemTitle {
            /// URLを開く
            static let browse = L10n.tr("Localizable", "clip_preview.option_menu_item_title.browse")
            /// 詳細情報を見る
            static let info = L10n.tr("Localizable", "clip_preview.option_menu_item_title.info")
            /// 再生設定を開く
            static let playConfig = L10n.tr("Localizable", "clip_preview.option_menu_item_title.play_config")
        }
    }
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
