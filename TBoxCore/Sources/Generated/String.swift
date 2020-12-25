// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// タグを追加
    internal static let clipTargetFinderViewAdditionTitle = L10n.tr("Localizable", "clip_target_finder_view_addition_title")
    /// OK
    internal static let clipTargetFinderViewDownloadErrorAction = L10n.tr("Localizable", "clip_target_finder_view_download_error_action")
    /// 保存時に問題が発生しました。後ほどもう一度お試しください
    internal static let clipTargetFinderViewDownloadErrorFailedToDownloadBody = L10n.tr("Localizable", "clip_target_finder_view_download_error_failed_to_download_body")
    /// 保存に失敗しました
    internal static let clipTargetFinderViewDownloadErrorFailedToDownloadTitle = L10n.tr("Localizable", "clip_target_finder_view_download_error_failed_to_download_title")
    /// 画像のダウンロードに失敗しました。通信環境を確認し、後ほどもう一度お試しください
    internal static let clipTargetFinderViewDownloadErrorFailedToSaveBody = L10n.tr("Localizable", "clip_target_finder_view_download_error_failed_to_save_body")
    /// ダウンロードできませんでした
    internal static let clipTargetFinderViewDownloadErrorFailedToSaveTitle = L10n.tr("Localizable", "clip_target_finder_view_download_error_failed_to_save_title")
    /// もう一度試す
    internal static let clipTargetFinderViewLoadingErrorAction = L10n.tr("Localizable", "clip_target_finder_view_loading_error_action")
    /// 通信環境の良い状態でもう一度お試しください
    internal static let clipTargetFinderViewLoadingErrorConnectionMessage = L10n.tr("Localizable", "clip_target_finder_view_loading_error_connection_message")
    /// 通信に失敗しました
    internal static let clipTargetFinderViewLoadingErrorConnectionTitle = L10n.tr("Localizable", "clip_target_finder_view_loading_error_connection_title")
    /// もう一度お試しください
    internal static let clipTargetFinderViewLoadingErrorInternalMessage = L10n.tr("Localizable", "clip_target_finder_view_loading_error_internal_message")
    /// 画像の探索に失敗しました
    internal static let clipTargetFinderViewLoadingErrorInternalTitle = L10n.tr("Localizable", "clip_target_finder_view_loading_error_internal_title")
    /// 以下のいずれかの可能性があります\n\n・ダウンロード可能な画像が存在しない\n・ダウンロードが許可されていないコンテンツ\n・通信環境の問題で時間がかかっている\n\n何度がお試しいただくと成功する場合があります
    internal static let clipTargetFinderViewLoadingErrorNotFoundMessage = L10n.tr("Localizable", "clip_target_finder_view_loading_error_not_found_message")
    /// 画像が見つかりませんでした
    internal static let clipTargetFinderViewLoadingErrorNotFoundTitle = L10n.tr("Localizable", "clip_target_finder_view_loading_error_not_found_title")
    /// 以下のいずれかの可能性があります\n\n・ダウンロード可能な画像が存在しない\n・ダウンロードが許可されていないコンテンツ\n・通信環境の問題で時間がかかっている\n\n何度がお試しいただくと成功する場合があります
    internal static let clipTargetFinderViewLoadingErrorTimeoutMessage = L10n.tr("Localizable", "clip_target_finder_view_loading_error_timeout_message")
    /// 画像が見つかりませんでした
    internal static let clipTargetFinderViewLoadingErrorTimeoutTitle = L10n.tr("Localizable", "clip_target_finder_view_loading_error_timeout_title")
    /// 既にクリップ済みのURLです。上書きしますか？
    internal static let clipTargetFinderViewOverwriteAlertBody = L10n.tr("Localizable", "clip_target_finder_view_overwrite_alert_body")
    /// キャンセル
    internal static let clipTargetFinderViewOverwriteAlertCancel = L10n.tr("Localizable", "clip_target_finder_view_overwrite_alert_cancel")
    /// OK
    internal static let clipTargetFinderViewOverwriteAlertOk = L10n.tr("Localizable", "clip_target_finder_view_overwrite_alert_ok")
    /// 画像を選択
    internal static let clipTargetFinderViewTitle = L10n.tr("Localizable", "clip_target_finder_view_title")
    /// OK
    internal static let confirmAlertOk = L10n.tr("Localizable", "confirm_alert_ok")
    /// タグの追加に失敗しました
    internal static let errorTagAddDefault = L10n.tr("Localizable", "error_tag_add_default")
    /// 同名のタグを追加することはできません
    internal static let errorTagAddDuplicated = L10n.tr("Localizable", "error_tag_add_duplicated")
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
