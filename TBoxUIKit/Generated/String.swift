// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// コピー
    internal static let clipInformationViewContextMenuCopy = L10n.tr("Localizable", "clip_information_view_context_menu_copy")
    /// 開く
    internal static let clipInformationViewContextMenuOpen = L10n.tr("Localizable", "clip_information_view_context_menu_open")
    /// 画像のURL
    internal static let clipInformationViewImageUrlTitle = L10n.tr("Localizable", "clip_information_view_image_url_title")
    /// サイトのURL
    internal static let clipInformationViewSiteUrlTitle = L10n.tr("Localizable", "clip_information_view_site_url_title")
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
