import UIKit

enum CollageLayout: String, CaseIterable, Identifiable {
    case square = "Square"
    case landscape = "Landscape"
    case portrait = "Portrait"
    
    var id: String { rawValue }
    
    var size: CGSize {
        switch self {
        case .square:
            return CGSize(width: 1080, height: 1080)
            
        case .landscape:
            return CGSize(width: 1920, height: 1080)
            
        case .portrait:
            return CGSize(width: 1080, height: 1920)
        }
    }
}

// 編集可能なコラージュデータ
struct CollageDraft {
    var layout: CollageLayout
    var template: CollageTemplate
    var imageIndices: [Int]
    var cropCenters: [CGPoint]
}

enum CollageRenderer {
    private static let margin: CGFloat = 24
    private static let spacing: CGFloat = 10
    
    // 写真の配置案
    private struct Arrangement {
        let template: CollageTemplate
        let imageIndices: [Int]
        let score: Double
    }
    
    // MARK: - Create Draft
    
    static func makeDraft(
        images:[UIImage],
        layout: CollageLayout,
        variation: Int = 0
    ) -> CollageDraft {
        let arrangements = (0..<20).map { index in
            let template = CollageTemplateFactory.make(
                photoCount: images.count,
                variation: index
            )
            
            return evaluate(
                template: template,
                images: images,
                canvasSize: layout.size
            )
        }
        
        let sorted = arrangements.sorted {
            $0.score < $1.score
        }
        
        let index = (variation % sorted.count + sorted.count) % sorted.count
        
        let selected = sorted[index]
        
        return CollageDraft(
            layout: layout,
            template: selected.template,
            imageIndices: selected.imageIndices,
            cropCenters: Array(
                repeating: CGPoint(x: 0.5, y: 0.5),
                count: images.count
            )
        )
    }
    
    // MARK: - Existing API
    
    static func render(
        images: [UIImage],
        layout: CollageLayout,
        variation: Int = 0
    ) -> UIImage? {
        guard(2...9).contains(images.count) else {
            return nil
        }
        
        let draft = makeDraft(
            images: images,
            layout: layout,
            variation: variation
        )
        
        return render(images: images, draft: draft)
    }
    
    // MARK: - Render Draft
    
    static func render(
        images: [UIImage],
        draft: CollageDraft,
        outputSize: CGSize? = nil
    ) -> UIImage? {
        let canvasSize = outputSize ?? draft.layout.size
        
        guard images.count == draft.imageIndices.count,
              draft.imageIndices.count == draft.template.slots.count,
              draft.cropCenters.count == draft.template.slots.count,
              canvasSize.width > 0,
              canvasSize.height > 0
        else {
            return nil
        }
        
        let scale = canvasSize.width / draft.layout.size.width
        let scaledMargin = margin * scale
        let scaledSpacing = spacing * scale
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(
            size: canvasSize,
            format: format
        )
        
        return renderer.image { context in
            // 背景を白にする
            UIColor.white.setFill()
            
            context.fill(
                CGRect(origin: .zero, size: canvasSize)
            )
            
            for (slotIndex, slot) in
                    draft.template.slots.enumerated() {
                let imageIndex = draft.imageIndices[slotIndex]
                
                guard images.indices.contains(imageIndex) else {
                    continue
                }
                
                let rect = slotRect(
                    for: slot,
                    canvasSize: canvasSize,
                    margin: scaledMargin,
                    spacing: scaledSpacing
                )
                
                drawImage(
                    images[imageIndex],
                    in: rect,
                    center: draft.cropCenters[slotIndex],
                    context: context.cgContext
                )
            }
        }
    }
    
    // MARK: - Slot Geometry
    
    static func slotRect(
        for slot: CollageSlot,
        canvasSize: CGSize,
        margin: CGFloat,
        spacing: CGFloat
    ) -> CGRect{
        let area = CGRect(
            x: margin,
            y: margin,
            width: canvasSize.width - margin * 2,
            height: canvasSize.height - margin * 2
        )
        
        let rect = CGRect(
            x: area.minX + slot.frame.minX * area.width,
            y: area.minY + slot.frame.minY * area.height,
            width: slot.frame.width * area.width,
            height: slot.frame.height * area.height
        )
        
        return rect.insetBy(
            dx: spacing / 2,
            dy: spacing / 2
        )
    }
    
    // MARK: - Layout Evaluation
    
    
    private static func evaluate(
        template: CollageTemplate,
        images: [UIImage],
        canvasSize: CGSize
    ) -> Arrangement {
        var remaining = Array(images.indices)
        var assignments: [Int] = []
        var totalScore = 0.0
        
        for slot in template.slots {
            let slotRatio = (slot.frame.width * canvasSize.width) / (slot.frame.height * canvasSize.height)
            
            // この枠と最も相性が良い写真を探す
            guard let best = remaining.min (by: {
                ratioDifference(
                    image: images[$0],
                    targetRatio: slotRatio
                ) < ratioDifference(
                    image: images[$1],
                    targetRatio: slotRatio
                )
            }) else {
                break
            }
            
            totalScore += ratioDifference(
                image: images[best],
                targetRatio: slotRatio
            )
            
            assignments.append(best)
            
            remaining.removeAll { $0 == best }
        }
        
        return Arrangement(
            template: template,
            imageIndices: assignments,
            score: totalScore
        )
    }
    
    private static func ratioDifference(
        image: UIImage,
        targetRatio: CGFloat
    ) -> Double {
        
        guard image.size.width > 0,
              image.size.height > 0,
              targetRatio > 0 else {
            return .infinity
        }
        
        let imageRatio = image.size.width / image.size.height
        
        return abs(
            log(Double(imageRatio / targetRatio))
        )
    }
    
    // MARK: - Image Drawing
    
    private static func drawImage(
        _ image: UIImage,
        in rect: CGRect,
        center: CGPoint,
        context: CGContext
    ) {
        let size = image.size
        
        guard size.width > 0,
              size.height > 0,
              rect.width > 0,
              rect.height > 0 else {
            return
        }
        
        let scale = max(
            rect.width / size.width,
            rect.height / size.height
        )
        
        let width = size.width * scale
        let height = size.height * scale
        
        let x = rect.minX + (rect.width - width) * center.x
        let y = rect.minY + (rect.height - height) * center.y
        
        let drawRect = CGRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
        
        context.saveGState()
        
        context.clip(to: rect)
        
        image.draw(in: drawRect)
        
        context.restoreGState()
    }
}
