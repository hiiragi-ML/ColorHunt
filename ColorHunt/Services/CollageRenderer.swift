import UIKit

enum CollageLayout: String, CaseIterable, Identifiable {
    case square = "Square"
    case portrait = "Portrait"
    
    var id: String { rawValue }
    
    var size: CGSize {
        switch self {
        case .square:
            return CGSize(width: 1080, height: 1080)
        case .portrait:
            return CGSize(width: 1080, height: 1920)
        }
    }
}

enum CollageRenderer {
    static func render(
        images: [UIImage],
        layout: CollageLayout
    ) -> UIImage? {
        guard (2...9).contains(images.count) else {
            return nil
        }
        
        let size = layout.size
        let margin: CGFloat = 24
        let spacing: CGFloat = 10
        
        let columns: Int
        
        switch layout {
        case .square:
            columns = images.count <= 3 ? images.count : 3
        case .portrait:
            columns = 2
        }
        
        let rows = Int(
            ceil(Double(images.count) / Double(columns))
        )
        
        let availableHeight = size.height - margin * 2 - CGFloat(rows - 1) * spacing
        
        let cellHeight = availableHeight / CGFloat(rows)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: format
        )
        
        return renderer.image { context in
            // 背景を白にする
            UIColor.white.setFill()
            context.fill(
                CGRect(origin: .zero, size: size)
            )
            
            for row in 0..<rows {
                let start = row * columns
                let itemsInRow = min(
                    columns,
                    images.count - start
                )
                
                let availableWidth = size.width - margin * 2 - CGFloat(itemsInRow - 1) * spacing
                
                let cellWidth = availableWidth / CGFloat(itemsInRow)
                
                for column in 0..<itemsInRow {
                    let index = start + column
                    
                    let rect = CGRect(
                        x: margin + CGFloat(column) * (cellWidth + spacing),
                        y: margin + CGFloat(row) * (cellHeight + spacing),
                        width: cellWidth,
                        height: cellHeight
                    )
                    
                    drawImage(
                        images[index],
                        in: rect,
                        context: context.cgContext
                    )
                }
            }
        }
    }
    private static func drawImage(
        _ image: UIImage,
        in rect: CGRect,
        context: CGContext
    ) {
        let imageSize = image.size
        
        guard imageSize.width > 0, imageSize.height > 0 else {
            return
        }
        
        // 領域を埋める倍率を求める
        let scale = max(
            rect.width / imageSize.width,
            rect.height / imageSize.height
        )
        
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        
        // 中央揃えの描画一
        let drawRect = CGRect(
            x: rect.midX - width / 2,
            y: rect.midY - height / 2,
            width: width,
            height: height
        )
        
        context.saveGState()
        context.clip(to: rect)
        image.draw(in: drawRect)
        context.restoreGState()
    }
}
