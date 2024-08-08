//
//  FetchImageListViewModel.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import Foundation
import SwiftUI
import Photos
import Combine


class PhotoViewModel: ObservableObject,FetchPhoto {
    
    @Published var progress = true                          //이미지 불러오는 중 여부
    @Published var assets: [PHAsset] = []                   //실제 보여질 이미지 리스트 -> Assets리스트로 수정
    @Published var accessDenied = false                     //앨범 접근 허용 여부
    

    
    init() {
        fetchAssets()
    }
    
    func fetchAssets() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite){ status in
            switch status{
            case .authorized:
                self.loadAssets()
            default:
                self.accessDenied = true
            }
        }
    }
    func fetchImageFromAsset(asset: PHAsset,targetSize:CGSize,completion: @escaping (UIImage?)->()){
        //앨범에서 이미지 및 비디오 요청 및 관리하는 클래스
        let imageManager = PHCachingImageManager()
        //요청할 때 옵션을 부여할 수 있는 클래스
        let options = PHImageRequestOptions()
        //이미지는 동기적으로 받아올 필요가 없기 때문에 false
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        //1. 옵션을 모두 설정한 뒤 이미지 및 비디오를 요청하고 image가 nil이 아닐 경우(옵셔널 바인당) 후 리스트에 추가
        //2. 이 메서드는 이미지 리스트 아이템 뷰에서 각각 호출되어 사용하도록 수정
        imageManager.requestImage(for: asset, targetSize:targetSize, contentMode: .aspectFill, options: options) { image, _ in
            completion(image)
        }
    }
    internal func loadAssets(){
        //필터링,정렬 등 받아온 결괏값의 옵션을 부여할 수 있는 클래스
        let fetchOptions = PHFetchOptions()
        //날짜 순으로 내림차순
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //Assets(항목)을 받아오는 메서드 (PHFetchResult 클래스 타입)
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        //1. Assets Results의 파라미터 (asset,index,stop) 중 Assets만 사용(일단은)
        //2. 페이지를 차례로 넘기는 메서드를 새로 구현하여 사용
        //3. 2번은 문제가 아니였기에 다시 처음부터 모든 Assets을 가져와 assets배열에 저장
        let group = DispatchGroup()
        let userInteractiveQueue = DispatchQueue.global(qos: .userInteractive)
        let mainQueue = DispatchQueue.main
        group.enter()
        userInteractiveQueue.async{
            defer{ group.leave() }
            fetchResult.enumerateObjects { (asset, _, _) in
                mainQueue.async{ [weak self] in
                    self?.assets.append(asset)
                }
            }
        }
        group.notify(queue: userInteractiveQueue){
            mainQueue.async{ [weak self] in
                self?.progress = false
            }
        }
    }
}
