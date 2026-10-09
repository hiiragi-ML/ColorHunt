import SwiftUI
import SwiftData

struct AlbumView: View{
    @Query(sort: \HuntPhoto.createdAt, order: .reverse)
    private var photos: [HuntPhoto]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View{
        NavigationStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 20){
                    Text("Your Colors.")
                        .font(.largeTitle.bold())
                    
                    Text("あなたが見つけた色のコレクション")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: columns, spacing: 12){
                        ForEach(HuntColor.palette){ color in
                            NavigationLink {
                                ColorAlbumDetailView(color: color)
                            } label: {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(color.color)
                                    .frame(height: 150)
                                    .overlay(
                                        alignment: .bottomLeading
                                    ) {
                                        VStack(alignment: .leading){
                                            Text(color.name)
                                                .font(.headline)
                                            
                                            Text(
                                                "\(photos.filter { $0.colorID == color.id }.count) photos"
                                            )
                                            .font(.caption)
                                        }
                                        .foregroundStyle(.white)
                                        .padding(16)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Album")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ColorAlbumDetailView: View {
    let color: HuntColor
    
    @Query(sort: \HuntPhoto.createdAt, order: .reverse)
    private var photos: [HuntPhoto]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    private var filteredPhotos: [HuntPhoto] {
        photos.filter { $0.colorID == color.id }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(filteredPhotos) { photo in
                    NavigationLink {
                        PhotoDetailView(photo: photo)
                    } label: {
                        PhotoThumbnail(photo: photo)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(color.name)
        .overlay {
            if filteredPhotos.isEmpty {
                ContentUnavailableView(
                    "写真がありません",
                    systemImage: "photo",
                    description: Text(
                        "この色の写真を集めてみましょう。"
                    )
                )
            }
        }
    }
}

#Preview {
    AlbumView()
}
