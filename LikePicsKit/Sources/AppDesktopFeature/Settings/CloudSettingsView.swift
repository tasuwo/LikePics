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
                Toggle(
                    String(localized: "iCloud Sync", bundle: .module, comment: "Toggle title for icloud sync setting"),
                    isOn: .init(
                        get: {
                            isCloudSyncSettingEnabled && cloudSyncAvailability.isAvailable == true
                        },
                        set: { enabled in
                            coordinator.wantsToSetCloudSync(to: enabled)
                        }
                    )
                )
                Text("Automatically upload and store all photos in iCloud so you can access them from any of your devices.", bundle: .module, comment: "Toggle description for icloud sync setting")
                    .lineLimit(nil)
                    .font(.callout)
                    .padding(.leading, 20)
            }
        }
        .alert(
            Text("Turn off iCloud Sync", bundle: .module, comment: "Alert title"),
            isPresented: $coordinator.isCloudSyncTurnOffConfirmationPresenting
        ) {
            Button(role: .destructive) {
                isCloudSyncSettingEnabled = false
                coordinator.dismissAlert()
            } label: {
                Text("Turn off", bundle: .module, comment: "Alert action")
            }
            Button(role: .cancel) {
                coordinator.dismissAlert()
            } label: {
                Text("Cancel", bundle: .module)
            }
        } message: {
            Text("Data on this device will no longer be shared with other iOS/iPadOS devices. If you turn on iCloud sync later, data on this device will be merged with data on other iOS/iPadOS devices.", bundle: .module, comment: "Alert message")
        }
        .alert(
            Text("iCloud Unavailable", bundle: .module, comment: "Alert title"),
            isPresented: $coordinator.isCloudSyncAlwaysTurnOffConfirmationPresenting
        ) {
            Button(role: .destructive) {
                isCloudSyncSettingEnabled = false
                coordinator.dismissAlert()
            } label: {
                Text("Always turn off", bundle: .module, comment: "Alert action")
            }
            Button(role: .cancel) {
                coordinator.dismissAlert()
            } label: {
                Text("Cancel", bundle: .module)
            }
        } message: {
            Text("Please sign in to iCloud or enable using iCloud for this app at device setting.\nData saved while iCloud unavailable will be merged with other devices data when iCloud avaialable.", bundle: .module, comment: "Alert message")
        }
        .alert(
            Text("iCloud Unavailable", bundle: .module, comment: "Alert title"),
            isPresented: $coordinator.isCloudSyncAlwaysTurnOnConfirmationPresenting
        ) {
            Button {
                coordinator.dismissAlert()
            } label: {
                Text("OK")
            }
            Button {
                isCloudSyncSettingEnabled = true
                coordinator.dismissAlert()
            } label: {
                Text("Turn on when available", bundle: .module, comment: "Alert action")
            }
        } message: {
            Text("Please sign in to iCloud or enable using iCloud for this app at device setting.\nData saved while iCloud unavailable will be merged with other devices data when iCloud avaialable.", bundle: .module, comment: "Alert message")
        }
        .padding([.leading, .trailing])
    }
}

#Preview {
    let availability = CloudSyncAvailability()
    return CloudSettingsView(cloudSyncAvailability: availability)
        .environment(availability)
}
