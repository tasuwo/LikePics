// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// はじめてのアルバムを追加する
    internal static let albumListViewEmptyActionTitle = L10n.tr("Localizable", "album_list_view_empty_action_title")
    /// 複数のクリップをアルバムにまとめることができます
    internal static let albumListViewEmptyMessage = L10n.tr("Localizable", "album_list_view_empty_message")
    /// アルバムがありません
    internal static let albumListViewEmptyTitle = L10n.tr("Localizable", "album_list_view_empty_title")
    /// アルバムの追加に失敗しました
    internal static let albumListViewErrorAtAddAlbum = L10n.tr("Localizable", "album_list_view_error_at_add_album")
    /// アルバムへ追加
    internal static let albumSelectionViewTitle = L10n.tr("Localizable", "album_selection_view_title")
    /// OK
    internal static let confirmAlertOk = L10n.tr("Localizable", "confirm_alert_ok")
    /// アルバムを探す
    internal static let placeholderSearchAlbum = L10n.tr("Localizable", "placeholder_search_album")
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
