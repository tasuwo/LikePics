//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("一般", systemImage: "gear")
                }
                .navigationTitle("一般")

            CloudSettingsView()
                .tabItem {
                    Label("iCloud", systemImage: "icloud")
                }
                .navigationTitle("iCloud")
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}

#Preview() {
    SettingsView()
}
