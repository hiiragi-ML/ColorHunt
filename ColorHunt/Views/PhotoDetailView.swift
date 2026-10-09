import SwiftUI
import SwiftData

struct PhotoDetailView: View{
    let photo: HuntPhoto
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    
    var body: some View{
        ScrollView {
            VStack(spacing: 20) {
                if let image = PhotoStore.load(photo.fileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    ContentUnavailableView(
                        "画像を読み込めません",
                        systemImage: "photo"
                    )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent(
                        "Color",
                        value: photo.colorID.uppercased()
                    )
                    
                    LabeledContent(
                        "Date",
                        value: photo.createdAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                }
                
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Photo", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Photo")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "この写真を削除しますか？",
            isPresented: $showDeleteConfirmation
        ) {
            Button("削除", role: .destructive) {
                deletePhoto()
            }
        } message: {
            Text("アプリ内に保存された写真が削除されます。")
        }
        .alert(
            "削除エラー",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func deletePhoto() {
        do {
            try PhotoStore.delete(photo.fileName)
            
            modelContext.delete(photo)
            try modelContext.save()
            
            dismiss()
        } catch {
            errorMessage = "写真の削除に失敗しました。"
        }
    }
}
