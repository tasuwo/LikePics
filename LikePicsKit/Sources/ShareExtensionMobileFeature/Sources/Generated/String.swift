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
    /// 画像を探す対象の有効なWebサイトURLが見つかりませんでした
    static let errorNoUrl = L10n.tr("Localizable", "error_no_url")
    /// 共有に失敗しました
    static let errorUnknown = L10n.tr("Localizable", "error_unknown")
    /// アルバム名
    static let placeholderAlbumName = L10n.tr("Localizable", "placeholder_album_name")
    /// タグ名
    static let placeholderTagName = L10n.tr("Localizable", "placeholder_tag_name")
    /// このタグの名前を入力してください
    static let tagListViewAlertForAddMessage = L10n.tr("Localizable", "tag_list_view_alert_for_add_message")
    /// 新規タグ
    static let tagListViewAlertForAddTitle = L10n.tr("Localizable", "tag_list_view_alert_for_add_title")
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
