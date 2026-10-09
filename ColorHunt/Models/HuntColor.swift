import SwiftUI
struct HuntColor: Identifiable{
    let id: String
    let name: String
    let japaneseName: String
    let hex: String
    let color: Color
    
    static let palette: [HuntColor] = [
        .init(id: "blue", name: "BLUE", japaneseName: "青", hex: "#477DBB", color: Color(red: 71/255, green: 125/255, blue: 187/255)),
        .init(id: "red", name: "RED", japaneseName: "赤", hex: "#D66A65", color: Color(red: 214/255, green: 106/255, blue: 101/255)),
        .init(id: "yellow", name: "YELLOW", japaneseName: "黄色", hex: "#E6B956", color: Color(red: 230/255, green: 185/255, blue: 86/255)),
        .init(id: "green", name: "GREEN", japaneseName: "緑", hex: "#539978", color: Color(red: 100/255, green: 153/255, blue: 120/255)),
        .init(id: "purple", name: "PURPLE", japaneseName: "紫", hex: "#9B80BF", color: Color(red: 155/255, green: 128/255, blue: 191/255)),
        .init(id: "orange", name: "ORANGE", japaneseName: "オレンジ", hex: "#E99A60", color: Color(red: 233/255, green: 154/255, blue: 96/255)),
        .init(id: "pink", name: "PINK", japaneseName: "ピンク", hex: "#ECA0B8", color: Color(red: 236/255, green: 160/255, blue: 184/255)),
        .init(id: "cyan", name: "CYAN", japaneseName: "水色", hex: "#61B9C3", color: Color(red: 97/255, green: 185/255, blue: 195/255)),
        .init(id: "brown", name: "BROWN", japaneseName: "茶色", hex: "#95745A", color: Color(red: 149/255, green: 116/255, blue: 90/255)),
        .init(id: "white", name: "WHITE", japaneseName: "白", hex: "D9D9D9", color: Color(red: 217/255, green: 217/255, blue: 217/255)),
        .init(id: "black", name: "BLACK", japaneseName: "黒", hex: "#424242", color: Color(red: 66/255, green: 66/255, blue: 66/255)),
        .init(id: "lime", name: "LIME", japaneseName: "黄緑", hex: "#9BC76D", color: Color(red: 155/255, green: 199/255, blue: 109/255))
    ]
    
    // 日付の計算に使用するカレンダー
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }
    
    // 指定した日付のテーマカラー
    static func color(for date: Date) -> HuntColor {
        let calendar = Self.calendar
        
        let start = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 10,
                day: 10
            )
        )!
        
        let days = calendar.dateComponents(
            [.day],
            from: start,
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        
        let count = palette.count
        let cycle = Int(floor(Double(days) / Double(count)))
        let index = days - cycle * count
        
        return palette[order(for: cycle)[index]]
    }
    
    // 12日ごとのシャッフル順
    private static func order(for cycle: Int) -> [Int] {
        let count = palette.count
        var result = Array(0..<count)
        
        // 再現可能な疑似乱数
        var seed = UInt64(bitPattern: Int64(cycle)) ^ 0x9E3779B97F4A7C15
        
        if count > 1 {
            for i in stride(
                from: count - 1,
                through: 1,
                by: -1
            ) {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                
                let j = Int(seed % UInt64(i + 1))
                result.swapAt(i, j)
            }
            
            // 前周期の最後の色と重複させない
            let previousLast = rawLast(for: cycle - 1)
            
            if result[0] == previousLast {
                result.swapAt(0, 1)
            }
        }
        
        return result
    }
    
    // シャッフル直後の最後の色
    private static func rawLast(for cycle: Int) -> Int {
        let count = palette.count
        var result = Array(0..<count)
        
        var seed = UInt64(bitPattern: Int64(cycle)) ^ 0x9E3779B97F4A7C15
        
        if count > 1 {
            for i in stride(
                from: count - 1,
                through: 1,
                by: -1
            ) {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                
                let j = Int(seed % UInt64(i + 1))
                result.swapAt(i, j)
            }
        }
        
        return result.last ?? 0
    }
}
