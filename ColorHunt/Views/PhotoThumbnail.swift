import SwiftUI
import UIKit

struct PhotoThumbnail: View{
    let photo: HuntPhoto
    
    var body: some View {
        Group{
            if let image = PhotoStore.load(photo.fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.15))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
    .frame(maxWidth: .infinity)
    .aspectRatio(1, contentMode: .fit)
    .clipped()
    .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

