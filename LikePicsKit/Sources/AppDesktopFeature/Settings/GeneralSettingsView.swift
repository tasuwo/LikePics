//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(\.userInterfaceStyle) var userInterfaceStyle
    @AppStorage(\.showHiddenItems, store: .appGroup) var showHiddenItems

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                Text("Theme:", bundle: .module, comment: "General setting")
                    .gridColumnAlignment(.trailing)
                Picker(String(localized: "", bundle: .module, comment: "Picker title placeholder in general setting."), selection: $userInterfaceStyle) {
                    Text("Light", bundle: .module, comment: "Display Theme").tag(UserInterfaceStyle.light)
                    Text("Dark", bundle: .module, comment: "Display Theme").tag(UserInterfaceStyle.dark)
                    Text("Auto", bundle: .module, comment: "Display Theme").tag(UserInterfaceStyle.unspecified)
                }
                .labelsHidden()
                .pickerStyle(.radioGroup)
            }

            GridRow {
                Text("Appearance:", bundle: .module, comment: "General setting")
                    .gridColumnAlignment(.trailing)
                Toggle(String(localized: "Show hidden items", bundle: .module, comment: "General setting"), isOn: $showHiddenItems)
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
