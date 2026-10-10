import UIKit
import Photos

enum PhotoLibraryService {
    enum SaveError: LocalizedError {
        case notAuthorized
        case failed
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "写真への追加が許可されていません。"
            case .failed:
                return "写真アプリへの保存に失敗しました。"
            }
        }
    }
    
    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        guard status == .authorized else {
            throw SaveError.notAuthorized
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(
                    from: image
                )
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(
                        throwing: error ?? SaveError.failed
                    )
                }
            }
        }
    }
}
