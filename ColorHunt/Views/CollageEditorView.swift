import SwiftUI
import UIKit

private enum CollageEditMode: String, CaseIterable {
    case swap = "Swap"
    case crop = "Crop"
}

struct CollageEditorView: View {
    let images: [UIImage]
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: CollageDraft
    @State private var editMode: CollageEditMode = .crop
    @State private var selectedSlot: Int?
    
    @State private var dragSlot: Int?
    @State private var dragStart: CGPoint?
    
    @State private var isSaving = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    init(
        images: [UIImage],
        layout: CollageLayout,
        variation: Int
    ) {
        self.images = images
        
        _draft = State(
            initialValue: CollageRenderer.makeDraft(
                images: images,
                layout: layout,
                variation: variation
            )
        )
    }
    
    // MARK: - Preview
    
    private var previewImage: UIImage? {
        let fullSize = draft.layout.size
        
        let previewWIdth: CGFloat = 480
        
        let size = CGSize(
            width: previewWIdth,
            height: previewWIdth + fullSize.height / fullSize.width
        )
        
        return CollageRenderer.render(
            images: images,
            draft: draft,
            outputSize: size
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    editorPreview
                    
                    Picker("Edit Mode", selection: $editMode) {
                        ForEach(
                            CollageEditMode.allCases,
                            id: \.self
                        ) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    editorControls
                    
                    Divider()
                    
                    Button {
                        Task {
                            await saveCollage()
                        }
                    } label: {
                        Label(
                            "Save to Photos",
                            systemImage: "square.and.arrow.down"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving)
                    
                    Button {
                        shareCollage()
                    } label: {
                        Label(
                            "Share",
                            systemImage: "square.and.arrow.up"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSaving)
                    
                    if isSaving {
                        ProgressView("保存中...")
                    }
                }
                .padding(16)
            }
            .navigationTitle("Collage Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareImage {
                    ShareSheet(image: shareImage)
                }
            }
            .alert(
                "エラー",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: {
                        if !$0 { errorMessage = nil }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert(
                "保存完了",
                isPresented: Binding(
                    get: { successMessage != nil },
                    set: {
                        if !$0 { successMessage = nil }
                    }
                )
            ) {
                Button("OK") {
                    successMessage = nil
                }
            } message: {
                Text(successMessage ?? "")
            }
        }
    }
    
    // MARK: - Editor Preview
    
    private var editorPreview: some View {
        
        GeometryReader { geometry in
            
            let canvas = draft.layout.size
            
            let scale = min(
                geometry.size.width / canvas.width,
                geometry.size.height / canvas.height
            )
            
            let displaySize = CGSize(
                width: canvas.width * scale,
                height: canvas.height * scale
            )
            
            ZStack {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .frame(
                            width: displaySize.width,
                            height: displaySize.height
                        )
                }
                
                ForEach(
                    Array(draft.template.slots.enumerated()),
                    id: \.offset
                ) { index, slot in
                    
                    let rect = displayRect(
                        for: slot,
                        displaySize: displaySize
                    )
                    
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .overlay {
                            if selectedSlot == index {
                                Rectangle()
                                    .strokeBorder(
                                        Color.blue,
                                        lineWidth: 3
                                    )
                            }
                        }
                        .frame(
                            width: rect.width,
                            height: rect.height
                        )
                        .position(
                            x: rect.midX,
                            y: rect.midY
                        )
                        .onTapGesture {
                            handleTap(at: index)
                        }
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    handleDrag(
                                        value,
                                        slotIndex: index,
                                        displayRect: rect
                                    )
                                }
                                .onEnded { _ in
                                    dragSlot = nil
                                    dragStart = nil
                                }
                        )
                }
            }
            .frame(
                width: displaySize.width,
                height: displaySize.height
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .frame(height: 440)
        .background(
            Color.gray.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
    
    private func displayRect(
        for slot: CollageSlot,
        displaySize: CGSize
    ) -> CGRect {
        
        let canvasSize = draft.layout.size
        
        let scale = displaySize.width / canvasSize.width
        
        let canvasRect = CollageRenderer.slotRect(
            for: slot,
            canvasSize: canvasSize,
            margin: 24,
            spacing: 10
        )
        
        return CGRect(
            x: canvasRect.minX * scale,
            y: canvasRect.minY * scale,
            width: canvasRect.width * scale,
            height: canvasRect.height * scale
        )
    }
    
    // MARK: - Tap / Swap
    
    private func handleTap(at index: Int) {
        
        if editMode == .crop {
            selectedSlot = index
            return
        }
        
        guard let first = selectedSlot else {
            selectedSlot = index
            return
        }
        
        if first == index {
            selectedSlot = nil
            return
        }
        
        draft.imageIndices.swapAt(first, index)
        draft.cropCenters.swapAt(first, index)
        
        selectedSlot = nil
    }
    
    // MARK: - Drag / Crop
    
    private func handleDrag(
        _ value: DragGesture.Value,
        slotIndex: Int,
        displayRect: CGRect
    ) {
        guard editMode == .crop else {
            return
        }
        
        selectedSlot = slotIndex
        
        if dragSlot != slotIndex {
            dragSlot = slotIndex
            dragStart = draft.cropCenters[slotIndex]
        }
        
        guard let start = dragStart else {
            return
        }
        
        let imageIndex = draft.imageIndices[slotIndex]
        
        guard images.indices.contains(imageIndex) else {
            return
        }
        
        let imageSize = images[imageIndex].size
        
        guard imageSize.width > 0,
              imageSize.height > 0 else {
            return
        }
        
        let scale = max(
            displayRect.width / imageSize.width,
            displayRect.height / imageSize.height
        )
        
        let overflowX = max(
            imageSize.width * scale - displayRect.width,
            0
        )
        
        let overflowY = max(
            imageSize.height * scale - displayRect.height,
            0
        )
        
        let newX = overflowX > 0
        ? start.x - value.translation.width / overflowX
        : start.x
        
        let newY = overflowY > 0
        ? start.y - value.translation.height / overflowY
        : start.y
        
        draft.cropCenters[slotIndex] = CGPoint(
            x: min(max(newX, 0), 1),
            y: min(max(newY, 0), 1)
        )
    }
    
    // MARK: - Controls
    
    @ViewBuilder
    private var editorControls: some View {
        
        if editMode == .swap {
            VStack(alignment: .leading, spacing: 10) {
                Text("Swap Photos")
                    .font(.headline)
                
                Text(
                    "入れ替えたい写真を2枚、順番にタップしてください。"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                if selectedSlot != nil {
                    Text("1枚目を選択中")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        } else {
            VStack(alignment: .leading, spacing: 14) {
                
                Text("Adjust Crop")
                    .font(.headline)
                
                Text(
                    "写真をタップして選択し、ドラッグで位置を調整できます。"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                if let index = selectedSlot {
                    
                    HStack {
                        Text("Horizontal")
                        
                        Slider(
                            value: cropBinding(
                                for: index,
                                horizontal: true
                            ),
                            in: 0...1
                        )
                    }
                    
                    HStack {
                        Text("Vertical")
                        
                        Slider(
                            value: cropBinding(
                                for: index,
                                horizontal: false
                            ),
                            in: 0...1
                        )
                    }
                    
                    Button("Reset Crop") {
                        draft.cropCenters[index] = CGPoint(
                            x: 0.5,
                            y: 0.5
                        )
                    }
                    .buttonStyle(.bordered)
                    
                } else {
                    Text("編集する写真を選択してください。")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func cropBinding(
        for index: Int,
        horizontal: Bool
    ) -> Binding<Double> {
        
        Binding(
            get: {
                let center = draft.cropCenters[index]
                
                return Double(
                    horizontal ? center.x : center.y
                )
            },
            set: { value in
                if horizontal {
                    draft.cropCenters[index].x = CGFloat(value)
                } else {
                    draft.cropCenters[index].y = CGFloat(value)
                }
            }
        )
    }
    
    // MARK: - Save / Share
    
    @MainActor
    private func saveCollage() async {
        guard let image = CollageRenderer.render(
            images: images,
            draft: draft
        ) else {
            errorMessage = "画像を生成できませんでした。"
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await PhotoLibraryService.save(image)
            successMessage = "写真アプリに保存しました。"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func shareCollage() {
        guard let image = CollageRenderer.render(
            images: images,
            draft: draft
        ) else {
            errorMessage = "画像を生成できませんでした。"
            return
        }
        
        shareImage = image
        showShareSheet = true
    }
}
