//
//  FetchImageListViewModel.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import Foundation
import Photos

class PhotoViewModel: ObservableObject {
    
    init() {
        fetchImages()
    }
    
    func fetchImages() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite){ status in
            switch status{
            case .authorized:
                print("성공")
            default:
                print("실패")
            }
        }
    }
}
