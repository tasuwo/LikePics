// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// 保存する画像の取得元となるURLを設定できます\nURLは画像の保存後に参照することができます
    internal static let clipCreationViewAlertForAddUrlMessage = L10n.tr("Localizable", "clip_creation_view_alert_for_add_url_message")
    /// URLを追加
    internal static let clipCreationViewAlertForAddUrlTitle = L10n.tr("Localizable", "clip_creation_view_alert_for_add_url_title")
    /// 保存する画像の取得元となるURLを編集します\nURLは画像の保存後に参照することができます
    internal static let clipCreationViewAlertForEditUrlMessage = L10n.tr("Localizable", "clip_creation_view_alert_for_edit_url_message")
    /// URLを編集
    internal static let clipCreationViewAlertForEditUrlTitle = L10n.tr("Localizable", "clip_creation_view_alert_for_edit_url_title")
    /// https://...
    internal static let clipCreationViewAlertForUrlPlaceholder = L10n.tr("Localizable", "clip_creation_view_alert_for_url_placeholder")
    /// OK
    internal static let clipCreationViewDownloadErrorAction = L10n.tr("Localizable", "clip_creation_view_download_error_action")
    /// 保存時に問題が発生しました。後ほどもう一度お試しください
    internal static let clipCreationViewDownloadErrorFailedToDownloadBody = L10n.tr("Localizable", "clip_creation_view_download_error_failed_to_download_body")
    /// 保存に失敗しました
    internal static let clipCreationViewDownloadErrorFailedToDownloadTitle = L10n.tr("Localizable", "clip_creation_view_download_error_failed_to_download_title")
    /// 画像のダウンロードに失敗しました。通信環境を確認し、後ほどもう一度お試しください
    internal static let clipCreationViewDownloadErrorFailedToSaveBody = L10n.tr("Localizable", "clip_creation_view_download_error_failed_to_save_body")
    /// ダウンロードできませんでした
    internal static let clipCreationViewDownloadErrorFailedToSaveTitle = L10n.tr("Localizable", "clip_creation_view_download_error_failed_to_save_title")
    /// もう一度試す
    internal static let clipCreationViewLoadingErrorAction = L10n.tr("Localizable", "clip_creation_view_loading_error_action")
    /// 通信環境の良い状態でもう一度お試しください
    internal static let clipCreationViewLoadingErrorConnectionMessage = L10n.tr("Localizable", "clip_creation_view_loading_error_connection_message")
    /// 通信に失敗しました
    internal static let clipCreationViewLoadingErrorConnectionTitle = L10n.tr("Localizable", "clip_creation_view_loading_error_connection_title")
    /// もう一度お試しください
    internal static let clipCreationViewLoadingErrorInternalMessage = L10n.tr("Localizable", "clip_creation_view_loading_error_internal_message")
    /// 画像の探索に失敗しました
    internal static let clipCreationViewLoadingErrorInternalTitle = L10n.tr("Localizable", "clip_creation_view_loading_error_internal_title")
    /// 以下のいずれかの可能性があります\n\n・ダウンロード可能な画像が存在しない\n・ダウンロードが許可されていないコンテンツ\n・通信環境の問題で時間がかかっている\n\n何度がお試しいただくと成功する場合があります
    internal static let clipCreationViewLoadingErrorNotFoundMessage = L10n.tr("Localizable", "clip_creation_view_loading_error_not_found_message")
    /// 画像が見つかりませんでした
    internal static let clipCreationViewLoadingErrorNotFoundTitle = L10n.tr("Localizable", "clip_creation_view_loading_error_not_found_title")
    /// 以下のいずれかの可能性があります\n\n・ダウンロード可能な画像が存在しない\n・ダウンロードが許可されていないコンテンツ\n・通信環境の問題で時間がかかっている\n\n何度がお試しいただくと成功する場合があります
    internal static let clipCreationViewLoadingErrorTimeoutMessage = L10n.tr("Localizable", "clip_creation_view_loading_error_timeout_message")
    /// 画像が見つかりませんでした
    internal static let clipCreationViewLoadingErrorTimeoutTitle = L10n.tr("Localizable", "clip_creation_view_loading_error_timeout_title")
    /// タグを追加する
    internal static let clipCreationViewTagAdditionCellTitle = L10n.tr("Localizable", "clip_creation_view_tag_addition_cell_title")
    /// 画像を選択
    internal static let clipCreationViewTitle = L10n.tr("Localizable", "clip_creation_view_title")
    /// 画像取得元のURLを追加する
    internal static let clipCreationViewUrlAdditionCellTitle = L10n.tr("Localizable", "clip_creation_view_url_addition_cell_title")
    /// OK
    internal static let confirmAlertOk = L10n.tr("Localizable", "confirm_alert_ok")
    /// タグの追加に失敗しました
    internal static let errorTagAddDefault = L10n.tr("Localizable", "error_tag_add_default")
    /// 同名のタグを追加することはできません
    internal static let errorTagAddDuplicated = L10n.tr("Localizable", "error_tag_add_duplicated")
    /// タグを探す
    internal static let placeholderSearchTag = L10n.tr("Localizable", "placeholder_search_tag")
    /// このタグの名前を入力してください
    internal static let tagListViewAlertForAddMessage = L10n.tr("Localizable", "tag_list_view_alert_for_add_message")
    /// タグ名
    internal static let tagListViewAlertForAddPlaceholder = L10n.tr("Localizable", "tag_list_view_alert_for_add_placeholder")
    /// 新規タグ
    internal static let tagListViewAlertForAddTitle = L10n.tr("Localizable", "tag_list_view_alert_for_add_title")
    /// はじめてのタグを追加する
    internal static let tagListViewEmptyActionTitle = L10n.tr("Localizable", "tag_list_view_empty_action_title")
    /// クリップをタグで分類すると、後から特定のタグに所属したクリップを一覧できます
    internal static let tagListViewEmptyMessage = L10n.tr("Localizable", "tag_list_view_empty_message")
    /// タグがありません
    internal static let tagListViewEmptyTitle = L10n.tr("Localizable", "tag_list_view_empty_title")
    /// タグを選択
    internal static let tagSelectionViewTitle = L10n.tr("Localizable", "tag_selection_view_title")
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
