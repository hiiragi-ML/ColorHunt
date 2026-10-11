import SwiftUI
import UserNotifications

struct ContentView: View {
    var body: some View {
        TabView{
            TodayView()
                .tabItem{
                    Label("Today", systemImage: "sun.max")
                }
            CalendarView()
                .tabItem{
                    Label("Calendar", systemImage: "calendar")
                }
            AlbumView()
                .tabItem{
                    Label("Album", systemImage: "square.grid.2x2")
                }
            CollageView()
                .tabItem{
                    Label("Create", systemImage: "paintpalette")
                }
            SettingsView()
                .tabItem{
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.primary)
    }
}

struct SettingsView: View{
    @AppStorage("notificationsEnabled")
    private var notificationsEnabled = false
    
    @AppStorage("notificationHour")
    private var notificationHour = 8
    
    @AppStorage("notificationMinute")
    private var notificationMinute = 0
    
    @State private var errorMessage: String?
    
    private var notificationTime: Binding<Date> {
        Binding(
            get: {
                HuntColor.calendar.date(
                    bySettingHour: notificationHour,
                    minute: notificationMinute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { newValue in
                let components = HuntColor.calendar.dateComponents(
                    [.hour, .minute],
                    from: newValue
                )
                
                notificationHour = components.hour ?? 8
                notificationMinute = components.minute ?? 0
                
                if notificationsEnabled {
                    Task {
                        await updateSchedule()
                    }
                }
            }
        )
    }
    
    var body: some View{
        NavigationStack{
            Form {
                Section {
                    Toggle(
                        "毎朝通知を受け取る",
                        isOn: $notificationsEnabled
                    )
                    .onChange(of: notificationsEnabled) {
                        _, enabled in
                        if enabled {
                            Task {
                                await enableNotifications()
                            }
                        } else {
                            NotificationManager.cancel()
                        }
                    }
                    
                    DatePicker(
                        "通知時刻",
                        selection: notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!notificationsEnabled)
                } header: {
                    Text("Daily Notification")
                } footer: {
                    Text(
                        "毎日、設定した時刻にその日のテーマカラーを通知します。"
                    )
                }
                
                Section("About") {
                    LabeledContent(
                        "Version",
                        value: "0.5.3"
                    )
                    LabeledContent(
                        "Colors",
                        value: "12"
                    )
                }
            }
            .navigationTitle("Settings")
            .alert(
                "通知の設定",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: {
                        if !$0 { errorMessage = nil }
                    }
                )
            ) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    @MainActor
    private func enableNotifications() async {
        do {
            let granted = try await NotificationManager.requestPermission()
            
            guard granted else {
                notificationsEnabled = false
                errorMessage = "通知が許可されていません。" + "iPhoneの設定アプリから通知を許可してください。"
                return
            }
            
            try await NotificationManager.reschedule()
        } catch {
            notificationsEnabled = false
            NotificationManager.cancel()
            errorMessage = "通知の設定に失敗しました。"
        }
    }
    
    @MainActor
    private func updateSchedule() async {
        do {
            try await NotificationManager.reschedule()
        } catch {
            errorMessage = "通知時刻の変更に失敗しました。"
        }
    }
}

#Preview {
    ContentView()
}
