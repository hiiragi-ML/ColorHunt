import SwiftUI
import UIKit

struct PhotoThumbnail: View{
    let photo: HuntPhoto
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.15))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    if let image = PhotoStore.load(photo.fileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .clipped()
                    } else {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                    }
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
    }
}

