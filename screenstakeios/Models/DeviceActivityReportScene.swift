import DeviceActivity
import SwiftUI

@main
struct DeviceActivityReportScene: DeviceActivityReportScene {
    var body: some DeviceActivityReportScene {
        // Configure the report context
        DeviceActivityReportView(context: .init("UsageReport")) { data in
            ScreenTimeReportView(data: data)
        }
    }
}