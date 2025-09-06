//
//  screenstake.swift
//  screenstake
//
//  Created by Andrew Grover on 9/6/25.
//

import DeviceActivity
import SwiftUI

@main
struct screenstake: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        // Add more reports here...
    }
}
