import SwiftUI
import UIKit

struct TemplateLibraryView: View {
    let images: [UIImage]
    let layout: CollageLayout
    let selectedVariation: Int
    let onSelect: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose a Template")
                        .font(.title2.bold())
                    
                    Text(
                        "写真に合わせて生成されたレイアウトから選択できます"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(
                            0..<CollageRenderer.templateCount,
                            id: \.self
                        ) { index in
                            if let template = CollageRenderer.template(
                                for: images,
                                layout: layout,
                                variation: index
                            ) {
                                Button {
                                    onSelect(index)
                                    dismiss()
                                } label: {
                                    VStack(spacing: 8) {
                                        TemplateThumbnail(
                                            template: template,
                                            layout: layout
                                        )
                                        
                                        HStack {
                                            Text("Layout \(index + 1)")
                                                .font(.caption)
                                                .foregroundStyle(.primary)
                                            
                                            Spacer()
                                            
                                            if selectedVariation % CollageRenderer.templateCount == index {
                                                Image(
                                                    systemName: "checkmark.circle.fill"
                                                )
                                                .foregroundStyle(.green)
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .background(
                                        Color.primary.opacity(0.05),
                                        in: RoundedRectangle(
                                            cornerRadius: 12
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Template Thumbnail

struct TemplateThumbnail: View {
    let template: CollageTemplate
    let layout: CollageLayout
    
    private let colors: [Color] = [
        Color(red: 0.55, green: 0.70, blue: 0.84),
        Color(red: 0.91, green: 0.73, blue: 0.44),
        Color(red: 0.62, green: 0.77, blue: 0.62),
        Color(red: 0.81, green: 0.62, blue: 0.69),
        Color(red: 0.67, green: 0.63, blue: 0.82)
    ]
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.12))
            .aspectRatio(
                layout.size.width / layout.size.height,
                contentMode: .fit
            )
            .overlay {
                GeometryReader { geometry in
                    let padding: CGFloat = 4
                    
                    let width = max(
                        geometry.size.width - padding * 2,
                        0
                    )
                    
                    let height = max(
                        geometry.size.height - padding * 2,
                        0
                    )
                    
                    ForEach(template.slots) { slot in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                colors[slot.id % colors.count]
                            )
                            .frame(
                                width: max(
                                    slot.frame.width * width - 3,
                                    0
                                ),
                                height: max(
                                    slot.frame.height * height - 3,
                                    0
                                )
                            )
                            .position(
                                x: padding + slot.frame.midX * width,
                                y: padding + slot.frame.midY * height
                            )
                    }
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
    }
}
