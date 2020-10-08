// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// キャンセル
    internal static let addingAlertActionCancel = L10n.tr("Localizable", "adding_alert_action_cancel")
    /// 保存
    internal static let addingAlertActionSave = L10n.tr("Localizable", "adding_alert_action_save")
    /// アルバムの読み込みに失敗しました
    internal static let addingClipsToAlbumViewErrorAtReadAlbums = L10n.tr("Localizable", "adding_clips_to_album_view_error_at_read_albums")
    /// アルバムの更新に失敗しました
    internal static let addingClipsToAlbumViewErrorAtUpdateAlbum = L10n.tr("Localizable", "adding_clips_to_album_view_error_at_update_album")
    /// アルバムへ追加
    internal static let addingClipsToAlbumViewTitle = L10n.tr("Localizable", "adding_clips_to_album_view_title")
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
    /// 削除
    internal static let clipInformationViewAlertForDeleteTagAction = L10n.tr("Localizable", "clip_information_view_alert_for_delete_tag_action")
    /// このタグを削除しますか？\nクリップ及び画像は削除されません
    internal static let clipInformationViewAlertForDeleteTagMessage = L10n.tr("Localizable", "clip_information_view_alert_for_delete_tag_message")
    /// タグを追加する
    internal static let clipItemPreviewViewAlertForAddTag = L10n.tr("Localizable", "clip_item_preview_view_alert_for_add_tag")
    /// アルバムに追加する
    internal static let clipItemPreviewViewAlertForAddToAlbum = L10n.tr("Localizable", "clip_item_preview_view_alert_for_add_to_album")
    /// クリップを削除する
    internal static let clipItemPreviewViewAlertForDeleteClipAction = L10n.tr("Localizable", "clip_item_preview_view_alert_for_delete_clip_action")
    /// 画像を削除する
    internal static let clipItemPreviewViewAlertForDeleteClipItemAction = L10n.tr("Localizable", "clip_item_preview_view_alert_for_delete_clip_item_action")
    /// クリップを削除すると、このクリップに含まれる全ての画像も同時に削除されます
    internal static let clipItemPreviewViewAlertForDeleteMessage = L10n.tr("Localizable", "clip_item_preview_view_alert_for_delete_message")
    /// 隠す
    internal static let clipItemPreviewViewAlertForHideAction = L10n.tr("Localizable", "clip_item_preview_view_alert_for_hide_action")
    /// このクリップは、設定が有効な間は全ての場所から隠されます
    internal static let clipItemPreviewViewAlertForHideMessage = L10n.tr("Localizable", "clip_item_preview_view_alert_for_hide_message")
    /// 正常に削除しました
    internal static let clipItemPreviewViewAlertForSuccessfullyDeleteMessage = L10n.tr("Localizable", "clip_item_preview_view_alert_for_successfully_delete_message")
    /// クリップの削除に失敗しました
    internal static let clipItemPreviewViewErrorAtDeleteClip = L10n.tr("Localizable", "clip_item_preview_view_error_at_delete_clip")
    /// 画像の削除に失敗しました
    internal static let clipItemPreviewViewErrorAtDeleteClipItem = L10n.tr("Localizable", "clip_item_preview_view_error_at_delete_clip_item")
    /// 画像の読み込みに失敗しました
    internal static let clipItemPreviewViewErrorAtReadImage = L10n.tr("Localizable", "clip_item_preview_view_error_at_read_image")
    /// クリップの読み込みに失敗しました
    internal static let clipPreviewPageViewErrorAtReadClip = L10n.tr("Localizable", "clip_preview_page_view_error_at_read_clip")
    /// 画像を選択
    internal static let clipTargetFinderViewTitle = L10n.tr("Localizable", "clip_target_finder_view_title")
    /// タグを追加する
    internal static let clipsListAlertForAddTag = L10n.tr("Localizable", "clips_list_alert_for_add_tag")
    /// アルバムに追加する
    internal static let clipsListAlertForAddToAlbum = L10n.tr("Localizable", "clips_list_alert_for_add_to_album")
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
    /// %d件のクリップを隠す
    internal static func clipsListAlertForHideAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "clips_list_alert_for_hide_action", p1)
    }

    /// 選択したクリップは、設定が有効な間は全ての場所から隠されます
    internal static let clipsListAlertForHideMessage = L10n.tr("Localizable", "clips_list_alert_for_hide_message")
    /// クリップの削除に失敗しました
    internal static let clipsListErrorAtDeleteClips = L10n.tr("Localizable", "clips_list_error_at_delete_clips")
    /// 画像の読み込みに失敗しました
    internal static let clipsListErrorAtGetImageData = L10n.tr("Localizable", "clips_list_error_at_get_image_data")
    /// クリップの読み込みに失敗しました
    internal static let clipsListErrorAtReadClips = L10n.tr("Localizable", "clips_list_error_at_read_clips")
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
    /// 検索に失敗しました
    internal static let searchEntryViewErrorAtSearch = L10n.tr("Localizable", "search_entry_view_error_at_search")
    /// キーワード
    internal static let searchEntryViewSearchBarPlaceholder = L10n.tr("Localizable", "search_entry_view_search_bar_placeholder")
    /// 検索
    internal static let searchEntryViewTitle = L10n.tr("Localizable", "search_entry_view_title")
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
    /// タグの追加に失敗しました
    internal static let tagListViewErrorAtAddTag = L10n.tr("Localizable", "tag_list_view_error_at_add_tag")
    /// クリップへのタグの追加に失敗しました
    internal static let tagListViewErrorAtAddTagsToClip = L10n.tr("Localizable", "tag_list_view_error_at_add_tags_to_clip")
    /// タグの削除に失敗しました
    internal static let tagListViewErrorAtDeleteTag = L10n.tr("Localizable", "tag_list_view_error_at_delete_tag")
    /// タグの読み込みに失敗しました
    internal static let tagListViewErrorAtReadTags = L10n.tr("Localizable", "tag_list_view_error_at_read_tags")
    /// クリップの取得に失敗しました
    internal static let tagListViewErrorAtSearchClip = L10n.tr("Localizable", "tag_list_view_error_at_search_clip")
    /// タグ
    internal static let tagListViewTitle = L10n.tr("Localizable", "tag_list_view_title")
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
    static let bundle = Bundle(for: BundleToken.self)
}

// swiftlint:enable convenience_type
