// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
enum L10n {
    /// OK
    static let confirmAlertOk = L10n.tr("Localizable", "confirm_alert_ok")
    /// タグの更新に失敗しました
    static let errorTagDefault = L10n.tr("Localizable", "error_tag_default")
    /// 同じ名前のタグが既に存在します
    static let errorTagRenameDuplicated = L10n.tr("Localizable", "error_tag_rename_duplicated")
    /// タグを探す
    static let placeholderSearchTag = L10n.tr("Localizable", "placeholder_search_tag")
    /// はじめてのタグを追加する
    static let tagListViewEmptyActionTitle = L10n.tr("Localizable", "tag_list_view_empty_action_title")
    /// クリップをタグで分類すると、後から特定のタグに所属したクリップを一覧できます
    static let tagListViewEmptyMessage = L10n.tr("Localizable", "tag_list_view_empty_message")
    /// タグがありません
    static let tagListViewEmptyTitle = L10n.tr("Localizable", "tag_list_view_empty_title")
    /// タグを選択
    static let tagSelectionViewTitle = L10n.tr("Localizable", "tag_selection_view_title")
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
