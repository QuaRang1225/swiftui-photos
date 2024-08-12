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
    @Published var assetList: [PHAsset] = []
    @Published var accessDenied = false                     //앨범 접근 허용 여부
    
    @Published var album:AlbumListItem?
    @Published var albums:[AlbumListItem] = []
    
    @Published var isAsscending = false
    @Published var isFilter = false
    
    private let group = DispatchGroup()
    private let userInteractiveQueue = DispatchQueue.global(qos: .userInteractive)
    private let fetchAlbumAssetQueue = DispatchQueue.global(qos: .userInteractive)
    private let mainQueue = DispatchQueue.main
    
    
    init() {
        fetchAssets()
        fetchAlbums()
    }
    func fetchAssets() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite){ status in
            switch status{
            case .authorized:
                self.fetchAlbumAssets(from: nil, condition: nil)
            default:
                self.accessDenied = true
            }
        }
    }
    func fetchAlbums() {
        self.albums.removeAll()
        let fetchOptions = PHFetchOptions()
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        userInteractiveQueue.async { [weak self] in
            self?.mainQueue.async {
                userAlbums.enumerateObjects { (collection, _, _) in
                    let asset = self?.fetchAlbumsFirstAssets(collection: collection)
                    self?.albums.append(AlbumListItem(id: collection.localIdentifier, asset: asset, title: collection.localizedTitle ?? "알수 없음", collection: collection))
                }
            }
        }
    }
    
    func fetchAlbumAssets(from collection: PHAssetCollection?,condition:NSPredicate?) {
        self.progress = true
        //필터링,정렬 등 받아온 결괏값의 옵션을 부여할 수 있는 클래스
        let fetchOptions = PHFetchOptions()
        //날짜 순으로 내림차순
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: isAsscending)]
        if let condition{
            fetchOptions.predicate = condition
        }
        //Assets(항목)을 받아오는 메서드 (PHFetchResult 클래스 타입)
        var assets = PHFetchResult<PHAsset>()
        if let collection{
            assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        }else{
            assets = PHAsset.fetchAssets(with: fetchOptions)
        }
        //비어있지 않은 Assets인 경우
        if assets.count != 0{
            group.enter()
            fetchAlbumAssetQueue.async { [weak self] in
                defer{ self?.group.leave() }
                let items = assets.objects(at: IndexSet(integersIn: 0..<assets.count))
                self?.mainQueue.async {
                    if let isEmpty = self?.assets.isEmpty,isEmpty{
                        self?.assets = items
                    }
                    self?.assetList = items
                }
            }
            group.notify(queue: userInteractiveQueue){
                self.mainQueue.async {
                    self.progress = false
                }
            }
        }else{
            self.assetList.removeAll()
            self.progress = false
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
    
    func fetchAlbumsFirstAssets(collection:PHAssetCollection)->PHAsset?{
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: isAsscending)]
        fetchOptions.fetchLimit = 1
        let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        return assets.firstObject
        
    }
    
    func fetchPhotosFirstAssets(mode:PhotosFilter) -> PHAsset?{
        let fetchOptions = PHFetchOptions()
        if mode == .bookmark{
            fetchOptions.predicate = NSPredicate(format: "favorite == YES")
        }
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: isAsscending)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        return fetchResult.firstObject
    }
    
    //이미지 저장
    func saveImageToPhotoLibrary() {
        guard let image = UIImage(systemName: "star") else { return }
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    _ = PHAssetCreationRequest.creationRequestForAsset(from: image)
                    // 필요한 경우, 추가적인 메타데이터 설정 등을 할 수 있습니다.
                }) { success, error in
                    if success {
                        print("Image successfully saved to the photo library.")
                    } else if let error = error {
                        print("Error saving image to the photo library: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Photo library access denied.")
            }
        }
    }
   
    func assetavorite(asset: PHAsset, isFavorite:Bool,completion:@escaping (PHAsset?,Bool) ->()){
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !isFavorite
        }){ success,_ in
            if success{
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)
                let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
                let updatedAsset = fetchResult.firstObject
                completion(updatedAsset,!isFavorite)
            }
        }
    }

    func deleteAssetLibrary(asset: PHAsset,completion:@escaping (PHAsset)->()) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
        }){ success ,_ in
            if success{
                completion(asset)
            }
        }
    }
}
