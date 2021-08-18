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
    /// アルバムへ追加する
    internal static let clipInformationViewLabelAlbumAddition = L10n.tr("Localizable", "clip_information_view_label_album_addition")
    /// 隠す
    internal static let clipInformationViewLabelClipHide = L10n.tr("Localizable", "clip_information_view_label_clip_hide")
    /// 編集
    internal static let clipInformationViewLabelClipItemEditUrl = L10n.tr("Localizable", "clip_information_view_label_clip_item_edit_url")
    /// 画像のURL
    internal static let clipInformationViewLabelClipItemImageUrl = L10n.tr("Localizable", "clip_information_view_label_clip_item_image_url")
    /// なし
    internal static let clipInformationViewLabelClipItemNoUrl = L10n.tr("Localizable", "clip_information_view_label_clip_item_no_url")
    /// 作成日
    internal static let clipInformationViewLabelClipItemRegisteredDate = L10n.tr("Localizable", "clip_information_view_label_clip_item_registered_date")
    /// サイズ
    internal static let clipInformationViewLabelClipItemSize = L10n.tr("Localizable", "clip_information_view_label_clip_item_size")
    /// 更新日
    internal static let clipInformationViewLabelClipItemUpdatedDate = L10n.tr("Localizable", "clip_information_view_label_clip_item_updated_date")
    /// サイトのURL
    internal static let clipInformationViewLabelClipItemUrl = L10n.tr("Localizable", "clip_information_view_label_clip_item_url")
    /// 作成日
    internal static let clipInformationViewLabelClipRegisteredDate = L10n.tr("Localizable", "clip_information_view_label_clip_registered_date")
    /// サイズ
    internal static let clipInformationViewLabelClipSize = L10n.tr("Localizable", "clip_information_view_label_clip_size")
    /// 更新日
    internal static let clipInformationViewLabelClipUpdatedDate = L10n.tr("Localizable", "clip_information_view_label_clip_updated_date")
    /// タグを追加する
    internal static let clipInformationViewLabelTagAddition = L10n.tr("Localizable", "clip_information_view_label_tag_addition")
    /// クリップのアルバム
    internal static let clipInformationViewSectionLabelAlbums = L10n.tr("Localizable", "clip_information_view_section_label_albums")
    /// クリップの情報
    internal static let clipInformationViewSectionLabelClipInfo = L10n.tr("Localizable", "clip_information_view_section_label_clip_info")
    /// このページの情報
    internal static let clipInformationViewSectionLabelClipItemInfo = L10n.tr("Localizable", "clip_information_view_section_label_clip_item_info")
    /// クリップのタグ
    internal static let clipInformationViewSectionLabelTags = L10n.tr("Localizable", "clip_information_view_section_label_tags")
    /// サイトのURL
    internal static let clipInformationViewSiteUrlTitle = L10n.tr("Localizable", "clip_information_view_site_url_title")
    /// 無題
    internal static let clipItemCellNoTitle = L10n.tr("Localizable", "clip_item_cell_no_title")
    /// サイトURL
    internal static let clipItemEditContentViewSiteTitle = L10n.tr("Localizable", "clip_item_edit_content_view_site_title")
    /// 編集
    internal static let clipItemEditContentViewSiteUrlEditTitle = L10n.tr("Localizable", "clip_item_edit_content_view_site_url_edit_title")
    /// なし
    internal static let clipItemEditContentViewSiteUrlEmpty = L10n.tr("Localizable", "clip_item_edit_content_view_site_url_empty")
    /// サイズ
    internal static let clipItemEditContentViewSizeTitle = L10n.tr("Localizable", "clip_item_edit_content_view_size_title")
    /// すべて削除
    internal static let searchEntryHeaderRemoveAll = L10n.tr("Localizable", "search_entry_header_remove_all")
    /// 最近の検索
    internal static let searchHistorySectionTitle = L10n.tr("Localizable", "search_history_section_title")
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
