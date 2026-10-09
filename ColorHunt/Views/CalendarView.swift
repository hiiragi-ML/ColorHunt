import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var photos: [HuntPhoto]
    
    @State private var monthOffset = 0
    
    private var calendar: Calendar {
        var result = HuntColor.calendar
        result.firstWeekday = 1
        return result
    }
    
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 4),
        count: 7
    )
    
    // v0.3で12色方式を導入した日
    private var colorSystemStart: Date {
        calendar.date(
            from: DateComponents(
                year: 2026, month: 10, day: 10
            )
        )!
    }
    
    // 表示中の月の1日
    private var firstDayOfMonth: Date {
        let today = Date()
        
        let components = calendar.dateComponents(
            [.year, .month],
            from: today
        )
        
        let currentMonth = calendar.date(from: components)!
        return calendar.date(
            byAdding: .month,
            value: monthOffset,
            to: currentMonth
        )!
    }
    
    // 月の先頭の空白を含む日付の配列
    private var monthCells: [Date?] {
        let firstDay = firstDayOfMonth
        
        let weekday = calendar.component(
            .weekday,
            from: firstDay
        )
        let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7
        
        guard let days = calendar.range(
            of: .day,
            in: .month,
            for: firstDay
        ) else {
            return []
        }
        
        let blanks = Array<Date?>(
            repeating: nil,
            count: leadingBlanks
        )
        
        let dates: [Date?] = days.compactMap { day in
            calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstDay
            )
        }.map { Optional($0) }
        
        return blanks + dates
    }
    
    private var weekdayNames: [String] {
        ["日", "月", "火", "水", "木", "金", "土"]
    }
    
    private var canMoveForward: Bool {
        monthOffset < 0
    }
    
    private func changeMonth(by amount: Int) {
        let newOffset = monthOffset + amount
        
        // 現在の月より未来には進めない
        guard newOffset <= 0 else {
            return
        }
        
        monthOffset = newOffset
    }
    
    private func photoCount(on date: Date) -> Int {
        photos.filter {
            calendar.isDate(
                $0.createdAt,
                inSameDayAs: date
            )
        }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    monthHeader
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(weekdayNames, id: \.self) { name in
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                        
                        ForEach(
                            Array(monthCells.enumerated()),
                            id: \.offset
                        ) { _, date in
                            if let date {
                                dayCell(for: date)
                            } else {
                                Color.clear
                                    .frame(height: 65)
                            }
                        }
                    }
                    
                    legend
                    
                    monthSummary
                }
                .padding(16)
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            Text(
                firstDayOfMonth.formatted(
                    .dateTime.year().month(.wide)
                )
            )
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 40, height: 40)
            }
            .disabled(!canMoveForward)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: .now)
        
        let hasTheme = date >= colorSystemStart && !isFuture
        
        let count = photoCount(on: date)
        let isToday = calendar.isDateInToday(date)
        
        NavigationLink {
            DayDetailView(date: date)
        } label: {
            VStack(spacing: 5) {
                Text(
                    "\(calendar.component(.day, from: date))"
                )
                .font(.system(
                    size: 14,
                    weight: isToday ? .bold : .regular
                ))
                .foregroundStyle(
                    isFuture ? Color.secondary : Color.primary
                )
                
                if hasTheme {
                    Circle()
                        .fill(HuntColor.color(for: date).color)
                        .frame(width: 21, height: 21)
                } else {
                    Color.clear
                        .frame(width: 21, height: 21)
                }
                
                Circle()
                    .fill(
                        count > 0 ? Color.primary : Color.clear
                    )
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 65)
            .background {
                if isToday {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary.opacity(0.08))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }
    
    private var legend: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                Text("テーマカラー")
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 5, height: 5)
                Text("写真あり")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    
    private var monthSummary: some View {
        let monthPhotos = photos.filter {
            calendar.isDate(
                $0.createdAt,
                equalTo: firstDayOfMonth,
                toGranularity: .month
            )
        }
        
        let activeDays = Set(
            monthPhotos.map{
                calendar.startOfDay(for: $0.createdAt)
            }
        ).count
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.headline)
            
            HStack{
                summaryItem(
                    title: "Photos",
                    value: monthPhotos.count
                )
                
                Spacer()
                
                summaryItem(
                    title: "Captured Days",
                    value: activeDays
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            Color.primary.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
    private func summaryItem(
        title: String,
        value: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct DayDetailView: View {
    let date: Date
    
    @Query(sort: \HuntPhoto.createdAt, order: .reverse)
    private var photos: [HuntPhoto]
    
    private var calendar: Calendar {
        HuntColor.calendar
    }
    
    private var dayPhotos: [HuntPhoto] {
        photos.filter {
            calendar.isDate(
                $0.createdAt,
                inSameDayAs: date
            )
        }
    }
    
    private var hasTheme: Bool {
        guard let start = calendar.date(
            from: DateComponents(
                year: 2026, month: 10, day: 10
            )
        ) else {
            return false
        }
        return date >= start
    }
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(
                    date.formatted(
                        .dateTime.weekday(.wide)
                    )
                )
                .font(.title2.bold())
                
                if hasTheme {
                    themeCard
                } else {
                    ContentUnavailableView(
                        "過去のカラーテーマ",
                        systemImage: "paintpalette",
                        description: Text(
                            "12食方式の導入前の日付です。"
                        )
                    )
                }
                
                HStack {
                    Text("Captures")
                        .font(.title3.bold())
                    
                    Spacer()
                    
                    Text("\(dayPhotos.count) photos")
                        .foregroundStyle(.secondary)
                }
                
                if dayPhotos.isEmpty {
                    ContentUnavailableView(
                        "写真がありません",
                        systemImage: "photo",
                        description: Text(
                            "この日に保存した写真はありません。"
                        )
                    )
                } else {
                    LazyVGrid(
                        columns: columns,
                        spacing: 8
                    ) {
                        ForEach(dayPhotos) { photo in
                            NavigationLink {
                                PhotoDetailView(photo: photo)
                            } label: {
                                PhotoThumbnail(photo: photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(
            date.formatted(
                .dateTime.year().month().day()
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var themeCard: some View {
        let color = HuntColor.color(for: date)
        
        return RoundedRectangle(cornerRadius: 20)
            .fill(color.color)
            .frame(height: 180)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S COLOR")
                        .font(.caption.bold())
                    
                    Text(color.name)
                        .font(.largeTitle.bold())
                    
                    Text(color.japaneseName)
                    Text(color.hex)
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(20)
            }
    }
}

#Preview {
    CalendarView()
}
