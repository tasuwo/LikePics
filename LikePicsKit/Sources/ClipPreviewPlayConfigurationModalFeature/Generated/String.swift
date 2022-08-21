// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    internal enum `Any` {
        internal enum ItemAnimationName {
            /// 左からスライド
            internal static let forward = L10n.tr("Localizable", "any.item_animation_name.forward")
            /// オフ
            internal static let off = L10n.tr("Localizable", "any.item_animation_name.off")
            /// 右からスライド
            internal static let reverse = L10n.tr("Localizable", "any.item_animation_name.reverse")
        }

        internal enum ItemOrderName {
            /// 通常
            internal static let forward = L10n.tr("Localizable", "any.item_order_name.forward")
            /// ランダム
            internal static let random = L10n.tr("Localizable", "any.item_order_name.random")
            /// 逆順
            internal static let reverse = L10n.tr("Localizable", "any.item_order_name.reverse")
        }

        internal enum ItemRangeName {
            /// 単一のクリップ
            internal static let clip = L10n.tr("Localizable", "any.item_range_name.clip")
            /// 全てのクリップ
            internal static let overall = L10n.tr("Localizable", "any.item_range_name.overall")
        }
    }

    internal enum Root {
        /// 再生設定
        internal static let title = L10n.tr("Localizable", "root.title")
        internal enum IntervalAlert {
            /// 画像が切り替わる間隔を%@秒から%@秒の範囲で設定します
            internal static func message(_ p1: Any, _ p2: Any) -> String {
                return L10n.tr("Localizable", "root.interval_alert.message", String(describing: p1), String(describing: p2))
            }

            /// 再生間隔
            internal static let title = L10n.tr("Localizable", "root.interval_alert.title")
        }

        internal enum MenuItemInterval {
            /// 編集
            internal static let editButton = L10n.tr("Localizable", "root.menu_item_interval.edit_button")
            /// %@秒
            internal static func seconds(_ p1: Any) -> String {
                return L10n.tr("Localizable", "root.menu_item_interval.seconds", String(describing: p1))
            }
        }

        internal enum MenuTitle {
            /// アニメーション
            internal static let animation = L10n.tr("Localizable", "root.menu_title.animation")
            /// 再生間隔
            internal static let interval = L10n.tr("Localizable", "root.menu_title.interval")
            /// ループ
            internal static let loop = L10n.tr("Localizable", "root.menu_title.loop")
            /// 順序
            internal static let order = L10n.tr("Localizable", "root.menu_title.order")
            /// 範囲
            internal static let range = L10n.tr("Localizable", "root.menu_title.range")
        }
    }
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
