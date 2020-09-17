// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
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
    /// クリップを削除する
    internal static let clipItemPreviewViewAlertForDeleteClipAction = L10n.tr("Localizable", "clip_item_preview_view_alert_for_delete_clip_action")
    /// 画像を削除する
    internal static let clipItemPreviewViewAlertForDeleteClipItemAction = L10n.tr("Localizable", "clip_item_preview_view_alert_for_delete_clip_item_action")
    /// クリップを削除すると、このクリップに含まれる全ての画像も同時に削除されます
    internal static let clipItemPreviewViewAlertForDeleteMessage = L10n.tr("Localizable", "clip_item_preview_view_alert_for_delete_message")
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
    /// タグの追加に失敗しました
    internal static let tagListViewErrorAtAddTag = L10n.tr("Localizable", "tag_list_view_error_at_add_tag")
    /// タグの削除に失敗しました
    internal static let tagListViewErrorAtDeleteTag = L10n.tr("Localizable", "tag_list_view_error_at_delete_tag")
    /// タグの読み込みに失敗しました
    internal static let tagListViewErrorAtReadTags = L10n.tr("Localizable", "tag_list_view_error_at_read_tags")
    /// クリップの取得に失敗しました
    internal static let tagListViewErrorAtSearchClip = L10n.tr("Localizable", "tag_list_view_error_at_search_clip")
    /// タグ
    internal static let tagListViewTitle = L10n.tr("Localizable", "tag_list_view_title")
    /// タグを追加する
    internal static let topClipsListViewAlertForAddTag = L10n.tr("Localizable", "top_clips_list_view_alert_for_add_tag")
    /// アルバムに追加する
    internal static let topClipsListViewAlertForAddToAlbum = L10n.tr("Localizable", "top_clips_list_view_alert_for_add_to_album")
    /// %d件のクリップを削除
    internal static func topClipsListViewAlertForDeleteAction(_ p1: Int) -> String {
        return L10n.tr("Localizable", "top_clips_list_view_alert_for_delete_action", p1)
    }

    /// クリップを削除すると、クリップに含まれる全ての画像も同時に削除されます
    internal static let topClipsListViewAlertForDeleteMessage = L10n.tr("Localizable", "top_clips_list_view_alert_for_delete_message")
    /// クリップの削除に失敗しました
    internal static let topClipsListViewErrorAtDeleteClips = L10n.tr("Localizable", "top_clips_list_view_error_at_delete_clips")
    /// 画像の読み込みに失敗しました
    internal static let topClipsListViewErrorAtGetImageData = L10n.tr("Localizable", "top_clips_list_view_error_at_get_image_data")
    /// クリップの読み込みに失敗しました
    internal static let topClipsListViewErrorAtReadClips = L10n.tr("Localizable", "top_clips_list_view_error_at_read_clips")
    /// キャンセル
    internal static let topClipsListViewRightBarItemForCancelTitle = L10n.tr("Localizable", "top_clips_list_view_right_bar_item_for_cancel_title")
    /// 選択
    internal static let topClipsListViewRightBarItemForSelectTitle = L10n.tr("Localizable", "top_clips_list_view_right_bar_item_for_select_title")
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
