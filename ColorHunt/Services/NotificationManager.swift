import Foundation
import UserNotifications

enum NotificationManager {
    private static let center = UNUserNotificationCenter.current()
    
    private static let daysToSchedule = 30
    
    // 通知の許可をリクエスト
    static func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }
    
    // 通知の予約を削除
    static func cancel() {
        let identifiers = (0..<daysToSchedule).map {
            "colorhunt-daily-\($0)"
        }
        
        center.removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }
    
    // 現在の設定で通知を再予約する
    static func reschedule() async throws {
        cancel()
        
        let settings = await center.notificationSettings()
        
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }
        
        let defaults = UserDefaults.standard
        
        guard defaults.bool(forKey: "notificationsEnabled") else {
            return
        }
        
        let hour = defaults.object(
            forKey: "notificationHour"
        ) as? Int ?? 8
        
        let minute = defaults.object(
            forKey: "notificationMinute"
        ) as? Int ?? 0
        
        let calendar = HuntColor.calendar
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        for offset in 0..<daysToSchedule {
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: startOfToday
            ) else {
                continue
            }
            
            guard let scheduledDate = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: day
            ) else {
                continue
            }
            
            // すでに過ぎた時刻には予約しない
            guard scheduledDate > now else {
                continue
            }
            
            let color = HuntColor.color(for: day)
            
            let content = UNMutableNotificationContent()
            content.title = "Today's Color: \(color.name)"
            content.body = "今日の色は「\(color.japaneseName)」！" + "日常の中でこの色を探して写真に残そう。"
            content.sound = .default
            
            var dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: scheduledDate
            )
            dateComponents.calendar = calendar
            dateComponents.timeZone = calendar.timeZone
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "colorhunt-daily-\(offset)",
                content: content,
                trigger: trigger
            )
            
            try await center.add(request)
        }
    }
}
