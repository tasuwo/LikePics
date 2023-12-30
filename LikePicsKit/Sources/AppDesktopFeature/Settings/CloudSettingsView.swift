//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct CloudSettingsView: View {
    @StateObject var coordinator: CloudSyncSettingCoordinator
    @AppStorage(\.isCloudSyncEnabled) private var isCloudSyncSettingEnabled
    @Environment(CloudSyncAvailability.self) var cloudSyncAvailability

    init(cloudSyncAvailability: CloudSyncAvailability) {
        _coordinator = .init(wrappedValue: .init(cloudSyncAvailability: cloudSyncAvailability))
    }

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("iCloud同期", isOn: .init(get: {
                    isCloudSyncSettingEnabled && cloudSyncAvailability.isAvailable == true
                }, set: { enabled in
                    coordinator.wantsToSetCloudSync(to: enabled)
                }))
                Text("すべての写真をiCloudに自動的にアップロードして保存し、任意のデバイスからアクセスして表示できるようにします。")
                    .lineLimit(nil)
                    .font(.callout)
                    .padding(.leading, 20)
            }
        }
        .alert(Text("Turn off iCloud Sync"),
               isPresented: $coordinator.isCloudSyncTurnOffConfirmationPresenting)
        {
            Button(role: .destructive) {
                isCloudSyncSettingEnabled = false
                coordinator.dismissAlert()
            } label: {
                Text("Turn off")
            }
            Button(role: .cancel) {
                coordinator.dismissAlert()
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Data on this device will no longer be shared with other iOS/iPadOS devices. If you turn on iCloud sync later, data on this device will be merged with data on other iOS/iPadOS devices.")
        }
        .alert(Text("iCloud Unavailable"),
               isPresented: $coordinator.isCloudSyncAlwaysTurnOffConfirmationPresenting)
        {
            Button(role: .destructive) {
                isCloudSyncSettingEnabled = false
                coordinator.dismissAlert()
            } label: {
                Text("Always turn off")
            }
            Button(role: .cancel) {
                coordinator.dismissAlert()
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Please sign in to iCloud or enable using iCloud for this app at device setting.\nData saved while iCloud unavailable will be merged with other devices data when iCloud avaialable.")
        }
        .alert(Text("iCloud Unavailable"),
               isPresented: $coordinator.isCloudSyncAlwaysTurnOnConfirmationPresenting)
        {
            Button {
                coordinator.dismissAlert()
            } label: {
                Text("OK")
            }
            Button {
                isCloudSyncSettingEnabled = true
                coordinator.dismissAlert()
            } label: {
                Text("Turn on when available")
            }
        } message: {
            Text("Please sign in to iCloud or enable using iCloud for this app at device setting.\nData saved while iCloud unavailable will be merged with other devices data when iCloud avaialable.")
        }
        .padding([.leading, .trailing])
    }
}
