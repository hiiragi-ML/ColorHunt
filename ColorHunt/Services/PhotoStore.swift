import Foundation
import UIKit

enum PhotoStore{
    private static var directory: URL{
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        
        return documents.appendingPathComponent(
            "HuntPhotos",
            isDirectory: true
        )
    }
    
    static func save(_ image: UIImage) throws -> String {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        
        let fileName = UUID().uuidString + ".jpg"
        let url = directory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(
            compressionQuality: 0.85
        ) else {
            throw PhotoStoreError.encodingFailed
        }
        
        try data.write(to: url, options: .atomic)
        return fileName
    }
    
    static func load(_ fileName: String) -> UIImage? {
        let url = directory.appendingPathComponent(
            (fileName as NSString).lastPathComponent
        )
        return UIImage(contentsOfFile: url.path)
    }
    
    static func delete(_ fileName: String) throws {
        let url = directory.appendingPathComponent(
            (fileName as NSString).lastPathComponent
        )
        
        if FileManager.default.fileExists(atPath: url.path){
            try FileManager.default.removeItem(at: url)
        }
    }
}

enum PhotoStoreError: Error{
    case encodingFailed
}
