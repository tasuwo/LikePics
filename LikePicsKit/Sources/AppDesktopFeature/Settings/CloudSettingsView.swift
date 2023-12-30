//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct CloudSettingsView: View {
    @AppStorage(\.isCloudSyncEnabled) private var isCloudSyncEnabled

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("iCloud同期", isOn: $isCloudSyncEnabled)
                Text("すべての写真をiCloudに自動的にアップロードして保存し、任意のデバイスからアクセスして表示できるようにします。")
                    .lineLimit(nil)
                    .font(.callout)
                    .padding(.leading, 20)
            }
        }
        .padding([.leading, .trailing])
    }
}

#Preview {
    CloudSettingsView()
}
