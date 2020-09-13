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
