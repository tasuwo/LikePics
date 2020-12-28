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
    /// %d件
    internal static func albumListCollectionViewCellCount(_ p1: Int) -> String {
        return L10n.tr("Localizable", "album_list_collection_view_cell_count", p1)
    }

    /// コピー
    internal static let clipInformationViewContextMenuCopy = L10n.tr("Localizable", "clip_information_view_context_menu_copy")
    /// 開く
    internal static let clipInformationViewContextMenuOpen = L10n.tr("Localizable", "clip_information_view_context_menu_open")
    /// 画像のURL
    internal static let clipInformationViewImageUrlTitle = L10n.tr("Localizable", "clip_information_view_image_url_title")
    /// 編集
    internal static let clipInformationViewLabelClipEditUrl = L10n.tr("Localizable", "clip_information_view_label_clip_edit_url")
    /// 隠す
    internal static let clipInformationViewLabelClipHide = L10n.tr("Localizable", "clip_information_view_label_clip_hide")
    /// なし
    internal static let clipInformationViewLabelClipItemNoUrl = L10n.tr("Localizable", "clip_information_view_label_clip_item_no_url")
    /// 登録日
    internal static let clipInformationViewLabelClipItemRegisteredDate = L10n.tr("Localizable", "clip_information_view_label_clip_item_registered_date")
    /// サイズ
    internal static let clipInformationViewLabelClipItemSize = L10n.tr("Localizable", "clip_information_view_label_clip_item_size")
    /// 更新日
    internal static let clipInformationViewLabelClipItemUpdatedDate = L10n.tr("Localizable", "clip_information_view_label_clip_item_updated_date")
    /// 画像のURL
    internal static let clipInformationViewLabelClipItemUrl = L10n.tr("Localizable", "clip_information_view_label_clip_item_url")
    /// 登録日
    internal static let clipInformationViewLabelClipRegisteredDate = L10n.tr("Localizable", "clip_information_view_label_clip_registered_date")
    /// 更新日
    internal static let clipInformationViewLabelClipUpdatedDate = L10n.tr("Localizable", "clip_information_view_label_clip_updated_date")
    /// サイトのURL
    internal static let clipInformationViewLabelClipUrl = L10n.tr("Localizable", "clip_information_view_label_clip_url")
    /// タグは登録されていません
    internal static let clipInformationViewLabelEmpty = L10n.tr("Localizable", "clip_information_view_label_empty")
    /// このクリップの情報
    internal static let clipInformationViewSectionLabelClip = L10n.tr("Localizable", "clip_information_view_section_label_clip")
    /// この画像の情報
    internal static let clipInformationViewSectionLabelClipItem = L10n.tr("Localizable", "clip_information_view_section_label_clip_item")
    /// タグ
    internal static let clipInformationViewSectionLabelTag = L10n.tr("Localizable", "clip_information_view_section_label_tag")
    /// サイトのURL
    internal static let clipInformationViewSiteUrlTitle = L10n.tr("Localizable", "clip_information_view_site_url_title")
    /// 未分類のクリップを閲覧する
    internal static let uncategorizedCellTitle = L10n.tr("Localizable", "uncategorized_cell_title")
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
