//
//  FetchImageListViewModel.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import Foundation

import SwiftUI
import Photos

class PhotoViewModel: ObservableObject {
    
    @Published var images: [UIImage] = []
    @Published var accessDenied = false
    
    init() {
        fetchImages()
    }
    
    func fetchImages() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite){ status in
            switch status{
            case .authorized:
                //필터링,정렬 등 받아온 결괏값의 옵션을 부여할 수 있는 클래스
                let fetchOptions = PHFetchOptions()
                //날짜 순으로 내림차순
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                //Assets(항목)을 받아오는 메서드 (PHFetchResult 클래스 타입)
                let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
                //Assets Results의 파라미터 (asset,index,stop) 중 Assets만 사용(일단은)
                fetchResult.enumerateObjects { (asset, _, _) in
                    self.getImageFromAsset(asset: asset)
                }
            default:
                self.accessDenied = true
            }
        }
    }
    func getImageFromAsset(asset: PHAsset) {
        //앨범에서 이미지 및 비디오 요청 및 관리하는 클래스
        let imageManager = PHImageManager.default()
        //요청할 때 옵션을 부여할 수 있는 클래스
        let options = PHImageRequestOptions()
        //이미지는 동기적으로 받아올 필요가 없기 때문에 false
        options.isSynchronous = false
        //옵션을 모두 설정한 뒤 이미지 및 비디오를 요청하고 image가 nil이 아닐 경우(옵셔널 바인당) 후 리스트에 추가
        imageManager.requestImage(for: asset, targetSize: .init(), contentMode: .aspectFill, options: options) { image, _ in
            if let image {
                DispatchQueue.main.async {
                    self.images.append(image)
                }
            }
        }
    }
}
