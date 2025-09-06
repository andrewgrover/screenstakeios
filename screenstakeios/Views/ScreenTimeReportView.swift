import SwiftUI
import DeviceActivity

struct ScreenTimeReportView: DeviceActivityReportView {
    let data: DeviceActivityReport.Data
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Screen Time Report")
                .font(.title2)
                .fontWeight(.semibold)
            
            if data.isEmpty {
                Text("No usage data available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(data.activitySegments, id: \.dateInterval) { segment in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Usage for \(segment.dateInterval.start.formatted(date: .abbreviated, time: .omitted))")
                            .font(.headline)
                        
                        ForEach(segment.categories, id: \.category) { categoryData in
                            CategoryUsageView(categoryData: categoryData)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .onAppear {
            // Store the usage data for the main app to access
            storeUsageData(data)
        }
    }
    
    private func storeUsageData(_ reportData: DeviceActivityReport.Data) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for segment in reportData.activitySegments {
            let dateKey = dateFormatter.string(from: segment.dateInterval.start)
            
            for categoryData in segment.categories {
                for appData in categoryData.applications {
                    // Store usage data in UserDefaults for main app to access
                    let bundleId = appData.application.bundleIdentifier ?? ""
                    let usage = appData.totalActivityDuration
                    let key = "real_usage_\(dateKey)_\(bundleId)"
                    
                    UserDefaults.standard.set(usage, forKey: key)
                    
                    print("📊 Stored real usage: \(bundleId) = \(usage) seconds")
                }
            }
        }
        
        // Notify main app that new data is available
        NotificationCenter.default.post(
            name: Notification.Name("ScreenTimeDataUpdated"),
            object: nil
        )
    }
}

struct CategoryUsageView: View {
    let categoryData: DeviceActivityReport.Data.ActivitySegment.Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(categoryData.applications, id: \.application.bundleIdentifier) { appData in
                HStack {
                    Text(appData.application.displayName ?? "Unknown App")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(formatDuration(appData.totalActivityDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}