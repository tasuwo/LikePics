// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// 画像のダウンロードに失敗しました。時間をおいて再度お試しください
    internal static let clipTargetFinderViewErrorAlertBodyFailedToDownloadImages = L10n.tr("Localizable", "clip_target_finder_view_error_alert_body_failed_to_download_images")
    /// 保存可能な画像が見つからなかったため、クリップできません
    internal static let clipTargetFinderViewErrorAlertBodyFailedToFindImages = L10n.tr("Localizable", "clip_target_finder_view_error_alert_body_failed_to_find_images")
    /// タイムアウトしました。保存可能な画像が存在しないか、通信環境の問題で取得に時間がかかっている可能性があります。通信環境の良い場所で再度お試しください
    internal static let clipTargetFinderViewErrorAlertBodyFailedToFindImagesTimeout = L10n.tr("Localizable", "clip_target_finder_view_error_alert_body_failed_to_find_images_timeout")
    /// 画像の保存に失敗しました。クリップをやり直してください
    internal static let clipTargetFinderViewErrorAlertBodyFailedToSaveImages = L10n.tr("Localizable", "clip_target_finder_view_error_alert_body_failed_to_save_images")
    /// 問題が発生しました。クリップをやり直してください
    internal static let clipTargetFinderViewErrorAlertBodyInternalError = L10n.tr("Localizable", "clip_target_finder_view_error_alert_body_internal_error")
    /// OK
    internal static let clipTargetFinderViewErrorAlertOk = L10n.tr("Localizable", "clip_target_finder_view_error_alert_ok")
    /// エラー
    internal static let clipTargetFinderViewErrorAlertTitle = L10n.tr("Localizable", "clip_target_finder_view_error_alert_title")
    /// 既にクリップ済みのURLです。上書きしますか？
    internal static let clipTargetFinderViewOverwriteAlertBody = L10n.tr("Localizable", "clip_target_finder_view_overwrite_alert_body")
    /// キャンセル
    internal static let clipTargetFinderViewOverwriteAlertCancel = L10n.tr("Localizable", "clip_target_finder_view_overwrite_alert_cancel")
    /// OK
    internal static let clipTargetFinderViewOverwriteAlertOk = L10n.tr("Localizable", "clip_target_finder_view_overwrite_alert_ok")
    /// 画像を選択
    internal static let clipTargetFinderViewTitle = L10n.tr("Localizable", "clip_target_finder_view_title")
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
