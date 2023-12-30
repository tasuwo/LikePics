//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(StorageKey.userInterfaceStyle.rawValue) var userInterfaceStyle: UserInterfaceStyle = .unspecified
    @AppStorage(StorageKey.showHiddenItems.rawValue) var showHiddenItems: Bool = false

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                Text("テーマ:")
                    .gridColumnAlignment(.trailing)
                Picker("", selection: $userInterfaceStyle) {
                    Text("ライト").tag(UserInterfaceStyle.light)
                    Text("ダーク").tag(UserInterfaceStyle.dark)
                    Text("自動").tag(UserInterfaceStyle.unspecified)
                }
                .labelsHidden()
                .pickerStyle(.radioGroup)
            }

            GridRow {
                Text("表示設定:")
                    .gridColumnAlignment(.trailing)
                Toggle("隠した項目を表示", isOn: $showHiddenItems)
                    .gridCellColumns(2)
            }

            GridRow {
                Color.clear
                    .gridCellUnsizedAxes([.vertical, .horizontal])
            }
        }
        .padding()
    }
}

#Preview {
    GeneralSettingsView()
}
