import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct TodayView: View{
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \HuntPhoto.createdAt, order: .reverse)
    private var photos: [HuntPhoto]
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private func todayPhotos(on date: Date) -> [HuntPhoto] {
        let calendar = Calendar.current
        let color = HuntColor.color(for: date)
        
        return photos.filter { photo in
            calendar.isDate(photo.createdAt, inSameDayAs: date) && photo.colorID == color.id
        }
    }
    
    var body: some View{
        NavigationStack{
            TimelineView(
                .periodic(from: .now, by: 60)
            ) { context in
                let color = HuntColor.color(for: context.date)
                let captures = todayPhotos(on: context.date)
                
                ScrollView{
                    VStack(alignment: .leading, spacing: 24){
                        VStack(alignment: .leading, spacing: 8){
                            Text("TODAY'S COLOR")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text("Find your color.")
                                .font(.largeTitle.bold())
                            Text("今日の色を日常の中から見つけよう。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        RoundedRectangle(cornerRadius: 24)
                            .fill(color.color)
                            .frame(height: 220)
                            .overlay(alignment: .bottomLeading){
                                VStack(alignment: .leading, spacing: 6){
                                    Text(color.name)
                                        .font(.system(
                                            size: 42,
                                            weight: .bold,
                                        ))
                                    Text(color.hex)
                                    Text(color.japaneseName)
                                }
                                .foregroundStyle(.white)
                                .padding(24)
                            }
                        
                        HStack{
                            Text("Today's captures")
                                .font(.title3.bold())
                            Spacer()
                            Text("\(captures.count) photos")
                                .foregroundStyle(.secondary)
                        }
                        
                        if captures.isEmpty{
                            ContentUnavailableView(
                                "まだ写真がありません",
                                systemImage: "camera",
                                description: Text("今日の色を探してみましょう。")
                            )
                        } else {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 8
                            ) {
                                ForEach(captures) { photo in
                                    NavigationLink {
                                        PhotoDetailView(photo: photo)
                                    } label: {
                                        PhotoThumbnail(photo: photo)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Button {
                            if UIImagePickerController
                                .isSourceTypeAvailable(.camera) {
                                showCamera = true
                            }else {
                                errorMessage = "カメラを利用できません。"
                            }
                        }label: {
                            Label(
                                "Take a Photo",
                                systemImage: "camera"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving)
                        
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images
                        ) {
                            Label(
                                "Choose from Library",
                                systemImage: "photo.on.rectangle"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSaving)
                        
                        if isSaving {
                            ProgressView("写真を保存中...")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(20)
                }
                .navigationTitle("ColorHunt")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showCamera) {
                    CameraPicker{ image in
                        savePhoto(image)
                    }
                    .ignoresSafeArea()
                }
                .onChange(of: selectedItem) { _, newItem in
                    guard let newItem else { return }
                    
                    Task {
                        await loadSelectedPhoto(newItem)
                    }
                }
                .alert(
                    "エラー",
                    isPresented: Binding(
                        get: {errorMessage != nil},
                        set: {if !$0 { errorMessage = nil }}
                    )
                ) {
                    Button("OK", role: .cancel){
                        errorMessage = nil
                    }
                } message: {
                    Text(errorMessage ?? "")
                }
            }
        }
    }
    
    @MainActor
    private func loadSelectedPhoto(
        _ item: PhotosPickerItem
    ) async {
        isSaving = true
        defer {
            isSaving = false
            selectedItem = nil
        }
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                errorMessage = "画像を読み込めませんでした。"
                return
            }
            
            savePhoto(image)
        } catch {
            errorMessage = "写真の読み込みに失敗しました。"
        }
    }
    
    @MainActor
    private func savePhoto(_ image: UIImage){
        var savedFileName: String?
        
        do {
            let fileName = try PhotoStore.save(image)
            savedFileName = fileName
            
            let photo = HuntPhoto(
                colorID: HuntColor.color(for: .now).id,
                fileName: fileName
            )
            
            modelContext.insert(photo)
            try modelContext.save()
        } catch {
            if let savedFileName {
                try? PhotoStore.delete(savedFileName)
            }
            
            modelContext.rollback()
            errorMessage = "写真の保存に失敗しました。"
        }
    }
}
#Preview{
    TodayView()
}
