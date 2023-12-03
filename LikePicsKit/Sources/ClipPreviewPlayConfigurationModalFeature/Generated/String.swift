// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
enum L10n {
    enum `Any` {
        enum ItemAnimationName {
            /// 左からスライド
            static let forward = L10n.tr("Localizable", "any.item_animation_name.forward")
            /// オフ
            static let off = L10n.tr("Localizable", "any.item_animation_name.off")
            /// 右からスライド
            static let reverse = L10n.tr("Localizable", "any.item_animation_name.reverse")
        }

        enum ItemOrderName {
            /// 通常
            static let forward = L10n.tr("Localizable", "any.item_order_name.forward")
            /// ランダム
            static let random = L10n.tr("Localizable", "any.item_order_name.random")
            /// 逆順
            static let reverse = L10n.tr("Localizable", "any.item_order_name.reverse")
        }

        enum ItemRangeName {
            /// 単一のクリップ
            static let clip = L10n.tr("Localizable", "any.item_range_name.clip")
            /// 全てのクリップ
            static let overall = L10n.tr("Localizable", "any.item_range_name.overall")
        }
    }

    enum Root {
        /// 再生設定
        static let title = L10n.tr("Localizable", "root.title")
        enum IntervalAlert {
            /// 画像が切り替わる間隔を%@秒から%@秒の範囲で設定します
            static func message(_ p1: Any, _ p2: Any) -> String {
                return L10n.tr("Localizable", "root.interval_alert.message", String(describing: p1), String(describing: p2))
            }

            /// 再生間隔
            static let title = L10n.tr("Localizable", "root.interval_alert.title")
        }

        enum MenuItemInterval {
            /// 編集
            static let editButton = L10n.tr("Localizable", "root.menu_item_interval.edit_button")
            /// %@秒
            static func seconds(_ p1: Any) -> String {
                return L10n.tr("Localizable", "root.menu_item_interval.seconds", String(describing: p1))
            }
        }

        enum MenuTitle {
            /// アニメーション
            static let animation = L10n.tr("Localizable", "root.menu_title.animation")
            /// 再生間隔
            static let interval = L10n.tr("Localizable", "root.menu_title.interval")
            /// ループ
            static let loop = L10n.tr("Localizable", "root.menu_title.loop")
            /// 順序
            static let order = L10n.tr("Localizable", "root.menu_title.order")
            /// 範囲
            static let range = L10n.tr("Localizable", "root.menu_title.range")
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
