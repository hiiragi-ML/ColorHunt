import SwiftUI
import SwiftData
import UIKit

struct CollageView: View {
    @Query(sort: \HuntPhoto.createdAt, order: .reverse)
    private var photos: [HuntPhoto]
    
    @State private var selectedColorID = HuntColor.palette[0].id
    
    @State private var selectedPhotoIDs: [UUID] = []
    @State private var layout: CollageLayout = .square
    @State private var previewImage: UIImage?
    
    @State private var isSaving = false
    @State private var showShareSheet = false
    @State private var showEditor = false
    @State private var showTemplateLibrary = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    @State private var variation = 0
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var filteredPhotos: [HuntPhoto] {
        photos.filter {
            $0.colorID == selectedColorID
        }
    }
    
    private var canGenerate: Bool {
        (2...9).contains(selectedPhotoIDs.count)
    }
        
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    colorSection
                    
                    photoSection
                    
                    layoutSection
                    
                    Button {
                        generateCollage()
                    } label: {
                        Label(
                            "Generate Collage",
                            systemImage: "square.grid.3x3"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canGenerate || isSaving)
                    
                    if let previewImage {
                        previewSection(image: previewImage)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedColorID) {_, _ in
                selectedPhotoIDs.removeAll()
                variation = 0
                previewImage = nil
            }
            .onChange(of: layout) { _, _ in
                variation = 0
                previewImage = nil
            }
            .onChange(of: photos.map(\.id)) { _, ids in
                selectedPhotoIDs.removeAll {
                    !ids.contains($0)
                }
                previewImage = nil
            }
            .sheet(isPresented: $showShareSheet) {
                if let previewImage {
                    ShareSheet(image: previewImage)
                }
            }
            .sheet(isPresented: $showEditor) {
                CollageEditorView(
                    images: selectedImages,
                    layout: layout,
                    variation: variation
                )
            }
            .sheet(isPresented: $showTemplateLibrary) {
                TemplateLibraryView(
                    images: selectedImages,
                    layout: layout,
                    selectedVariation: variation
                ) { selectedIndex in
                    variation = selectedIndex
                    generateCollage()
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
                Button("OK", role: .cancel) {
                    successMessage = nil
                }
            } message: {
                Text(successMessage ?? "")
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("photo Collage")
                .font(.largeTitle.bold())
            
            Text("集めた色から、一つの作品を。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Color Selection
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("1. Choose a Color")
                .font(.headline)
            
            Picker("Color", selection: $selectedColorID) {
                ForEach(HuntColor.palette) { color in
                    Text(color.name)
                        .tag(color.id)
                }
            }
            .pickerStyle(.menu)
            
            if let color = HuntColor.palette.first(
                where: { $0.id == selectedColorID }
            ) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.color)
                        .frame(width: 48, height: 48)
                    
                    VStack(alignment: .leading) {
                        Text(color.name)
                            .font(.headline)
                        
                        Text(color.japaneseName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(filteredPhotos.count) photos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Photo Selection
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("2. Select Photos")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedPhotoIDs.count) / 9")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("2~9枚の写真を選択してください。")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if filteredPhotos.isEmpty{
                ContentUnavailableView(
                    "写真がありません",
                    systemImage: "photo",
                    description: Text(
                        "まずこの色の写真を集めてください。"
                    )
                )
            }else {
                LazyVGrid(
                    columns: columns,
                    spacing: 8
                ) {
                    ForEach(filteredPhotos) { photo in
                        Button {
                            toggleSelection(photo.id)
                        } label: {
                            PhotoThumbnail(photo: photo)
                                .overlay(alignment: .topTrailing) {
                                    selectionBadge(for: photo.id)
                                        .padding(6)
                                }
                                .overlay {
                                    if selectedPhotoIDs.contains(photo.id) {
                                        RoundedRectangle(
                                            cornerRadius: 12
                                        )
                                        .strokeBorder(
                                            Color.accentColor,
                                            lineWidth: 3
                                        )
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func selectionBadge(for id: UUID) -> some View {
        let selected = selectedPhotoIDs.contains(id)
        
        return Image(
            systemName: selected ? "checkmark.circle.fill" : "circle"
        )
        .font(.title3)
        .foregroundStyle(selected ? Color.accentColor : Color.white)
        .shadow(color: .black.opacity(0.5), radius: 2)
    }
    
    private func toggleSelection(_ id: UUID) {
        if let index = selectedPhotoIDs.firstIndex(of: id) {
            selectedPhotoIDs.remove(at: index)
        }else if selectedPhotoIDs.count < 9 {
            selectedPhotoIDs.append(id)
        }
        
        previewImage = nil
    }
    
    // MARK: - Layout Selection
    
    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 12){
            Text("3. Choose Layout")
                .font(.headline)
            
            Picker("Layout", selection: $layout) {
                ForEach(CollageLayout.allCases) { item in
                    Text(item.rawValue)
                        .tag(item)
                }
            }
            .pickerStyle(.segmented)
            
            Text(
                "\(Int(layout.size.width)) × \(Int(layout.size.height)) px"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Preview
    
    private func previewSection(
        image: UIImage
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack{
                Text("Preview")
                    .font(.title3.bold())
                
                Spacer()
                
                Text("Variation \(variation + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            
            Button {
                shuffleCollage()
            } label: {
                Label(
                    "Shuffle Layout",
                    systemImage: "shuffle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isSaving)
            
            Button {
                showTemplateLibrary = true
            } label: {
                Label(
                    "Choose Template",
                    systemImage: "rectangle.grid.2x2"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isSaving)
            
            Button {
                showEditor = true
            } label: {
                Label(
                    "Edit Collage",
                    systemImage: "slider.horizontal.3"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isSaving)
            
            Divider()
            
            Button {
                Task {
                    await saveCollage(image)
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
                showShareSheet = true
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
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Generate
    
    private func generateCollage() {
        guard canGenerate else { return }
        
        let selectedImages: [UIImage] = selectedPhotoIDs
            .compactMap { id in
                guard let photo = photos.first(
                    where: { $0.id == id }
                ) else {
                    return nil
                }
                
                return PhotoStore.load(photo.fileName)
            }
        
        guard selectedImages.count == selectedPhotoIDs.count,
              let image = CollageRenderer.render(
                images: selectedImages,
                layout: layout,
                variation: variation
              ) else {
            errorMessage = "コラージュを生成できませんでした。"
            return
        }
        previewImage = image
    }
    
    private func shuffleCollage() {
        variation += 1
        generateCollage()
    }
    
    private var selectedImages: [UIImage] {
        selectedPhotoIDs.compactMap { id in
            guard let photo = photos.first(
                where: { $0.id == id }
            ) else {
                return nil
            }
            
            return PhotoStore.load(photo.fileName)
        }
    }
    
    // MARK: - Save
    
    @MainActor
    private func saveCollage(_ image: UIImage) async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await PhotoLibraryService.save(image)
            
            successMessage = "コラージュを写真アプリに保存しました。"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CollageView()
}
