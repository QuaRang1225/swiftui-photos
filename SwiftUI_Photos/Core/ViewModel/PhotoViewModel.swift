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
    
    @Published var assets: [PHAsset] = []                   //실제 보여질 이미지 리스트 -> Assets리스트로 수정
    @Published var accessDenied = false                     //앨범 접근 허용 여부
    private var fetchResult: PHFetchResult<PHAsset>?        //Assets 페이지 result
    private var isFetching = false                          //페이지 업로드 여부
    private var lastFetchedIndex = 0                        //마지막으로 불러온 Assets index
    private let fetchLimit = 20                             //불러오는 Asset 개수 제한
    
    init() {
        fetchAssets()
    }
    
    func fetchAssets() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite){ status in
            switch status{
            case .authorized:
                //필터링,정렬 등 받아온 결괏값의 옵션을 부여할 수 있는 클래스
                let fetchOptions = PHFetchOptions()
                //날짜 순으로 내림차순
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                //Assets(항목)을 받아오는 메서드 (PHFetchResult 클래스 타입)
                self.fetchResult = PHAsset.fetchAssets(with: fetchOptions)
                //1. Assets Results의 파라미터 (asset,index,stop) 중 Assets만 사용(일단은)
                //2. 페이지를 차례로 넘기는 메서를 새로 구현하여 사용
                self.loadNextAssets()
            default:
                self.accessDenied = true
            }
        }
    }
    func fetchImageFromAsset(asset: PHAsset,completion: @escaping (UIImage?)->()){
        //앨범에서 이미지 및 비디오 요청 및 관리하는 클래스
        let imageManager = PHImageManager.default()
        //요청할 때 옵션을 부여할 수 있는 클래스
        let options = PHImageRequestOptions()
        //이미지는 동기적으로 받아올 필요가 없기 때문에 false
        options.isSynchronous = false
        //1. 옵션을 모두 설정한 뒤 이미지 및 비디오를 요청하고 image가 nil이 아닐 경우(옵셔널 바인당) 후 리스트에 추가
        //2. 이 메서드는 이미지 리스트 아이템 뷰에서 각각 호출되어 사용하도록 수정
        imageManager.requestImage(for: asset, targetSize: .init(), contentMode: .aspectFill, options: options) { image, _ in
            completion(image)
        }
    }
    func loadNextAssets(){
        //Assets result 옵셔널 바인딩 및 아직 Assets을 가져오지 않았을 때 메서드 실행
        guard let fetchResult, !isFetching else { return }
        //20씩 Assets을 불러오기 때문에 마지막 인덱스는 현재까지의 이미지 개수 + 20 혹은 전체 Assets 개수로 지정
        //마지막 Assets 목록은 정확하게 20의 배수가 아닐 수도 있음으로 fetchResult.count를 사용
        let lastIndex = min(lastFetchedIndex + fetchLimit,fetchResult.count)
        //모든 Assets을 불러왔으면 이 메서드에 진입하지 않기 위해 추가
        guard lastIndex > lastFetchedIndex else {
            isFetching = false
            return
        }
        //루프 자체는 background에서 돌아가지만 값 업데이트는 뷰와 직접적으로 바인딩 되야하기 때문에 main queue 사용
        DispatchQueue.global(qos: .userInitiated).async {
            for i in self.lastFetchedIndex..<lastIndex{
                //인덱스로 아이템 searching
                let asset = fetchResult.object(at: i)
                DispatchQueue.main.async {
                    self.assets.append(asset)
                    //Assets 마지막 목록을 가져왔을 경우 범위초과를 방지
                    //정해진 인덱스값대로 아이템을 모두 가져왔음을 알리고 마지막 인덱스 업데이트
                    if i == lastIndex - 1{
                        self.isFetching = false
                        self.lastFetchedIndex = lastIndex
                    }
                }
            }
        }
    }
}
