//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct SettingsView: View {
    @Environment(CloudSyncAvailability.self) var cloudSyncAvailability

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label(String(localized: "General", bundle: .module, comment: "Setting Title"), systemImage: "gear")
                }
                .navigationTitle(Text("General", bundle: .module, comment: "Setting Title"))

            CloudSettingsView(cloudSyncAvailability: cloudSyncAvailability)
                .tabItem {
                    Label(String(localized: "iCloud", bundle: .module, comment: "Setting Title"), systemImage: "icloud")
                }
                .navigationTitle(Text("iCloud", bundle: .module, comment: "Setting Title"))
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}

#Preview() {
    let availability = CloudSyncAvailability()
    return SettingsView()
        .environment(availability)
}
