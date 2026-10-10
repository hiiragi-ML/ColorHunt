import Foundation
import CoreGraphics

// テンプレート内の1枚分の写真枠
struct CollageSlot: Identifiable {
    let id: Int
    // キャンパス全体を0~1で表した相対座標
    let frame: CGRect
}

// コラージュのテンプレート
struct CollageTemplate: Identifiable {
    let id: String
    let slots: [CollageSlot]
}

// テンプレートを生成するサービス
enum CollageTemplateFactory {
    static func make(
        photoCount: Int,
        variation: Int
    ) -> CollageTemplate {
        let count = max(1, photoCount)
        var rectangles: [CGRect] = []
        
        split(
            rect: CGRect(x: 0, y: 0, width: 1, height: 1),
            count: count,
            depth: 0,
            variation: variation,
            result: &rectangles
        )
        
        let slots = rectangles.enumerated().map { index, rect in
            CollageSlot(id: index, frame: rect)
        }
        
        return CollageTemplate(
            id: "auto-\(count)-\(variation)",
            slots: slots
        )
    }
    
    private static func split(
        rect: CGRect,
        count: Int,
        depth: Int,
        variation: Int,
        result: inout [CGRect]
    ) {
        // 写真枠が1つになったら分割を終了
        guard count > 1 else {
            result.append(rect)
            return
        }
        
        // 分割する方向を決定
        let verticalSplit: Bool
        
        if rect.width > rect.height * 1.25 {
            verticalSplit = true
        } else if rect.height > rect.width * 1.25 {
            verticalSplit = false
        } else {
            verticalSplit = (depth + variation).isMultiple(of: 2)
        }
        
        // 分割位置にバリエーションをもたせる
        let ratios: [CGFloat] = [0.35, 0.42, 0.5, 0.58, 0.65]
        
        let ratioIndex = (
            depth * 3 + variation * 7 + count
        ) % ratios.count
        
        let ratio = ratios[ratioIndex]
        
        // 写真枚数も左右・上下に分配する
        let firstCount = max(
            1,
            min(
                count - 1,
                count / 2 + ((depth + variation) % 3 - 1)
            )
        )
        
        let secondCount = count - firstCount
        
        let firstRect: CGRect
        let secondRect: CGRect
        
        if verticalSplit{
            let firstWidth = rect.width * ratio
            
            firstRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: firstWidth,
                height: rect.height
            )
            
            secondRect = CGRect(
                x: rect.minX + firstWidth,
                y: rect.minY,
                width: rect.width - firstWidth,
                height: rect.height
            )
        } else {
            let firstHeight = rect.height * ratio
            
            firstRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width,
                height: firstHeight
            )
            
            secondRect = CGRect(
                x: rect.minX,
                y: rect.minY + firstHeight,
                width: rect.width,
                height: rect.height - firstHeight
            )
        }
        
        split(
            rect: firstRect,
            count: firstCount,
            depth: depth + 1,
            variation: variation,
            result: &result
        )
        
        split(
            rect: secondRect,
            count: secondCount,
            depth: depth + 2,
            variation: variation + 1,
            result: &result
        )
    }
}
