//
//  FetchAssets.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/7/24.
//

import Foundation
import Photos
import UIKit

protocol FetchPhoto{
    ///**모든 Assets를 불러오는 매서드**
    func fetchAssets()
    ///**모든 앨범 정보를 불러오는 매서드**
    func fetchAlbums()
    ///**특정 Asset의 이미지를 불러오는 매서드**
    func fetchImageFromAsset(asset: PHAsset,targetSize:CGSize,completion: @escaping (UIImage?)->())
    ///**Asset 리스트를 업데이트 하는 메서드**
    func fetchAlbumAssets(from collection: PHAssetCollection?,condition:NSPredicate?)
    ///**앨범의 첫사진을 불러오는 메서드**
    func fetchAlbumsFirstAssets(collection:PHAssetCollection)->PHAsset?
    ///**카테고리모드애 따라 Asset을 불러오는 메서드**
    func fetchPhotosFirstAssets(mode:PhotosFilter) -> PHAsset?
    ///**사진을 저장하는 메서드**
    /// - 지금은 사용하지 않음
    func saveImageToPhotoLibrary()
    ///**즐겨찾기에 추가 요청 메서드**
    func assetFavorite(asset: PHAsset, isFavorite:Bool,completion:@escaping (PHAsset?,Bool) ->())
    ///**사진을 삭제하는 메서드**
    func deleteAssetLibrary(asset: PHAsset,completion:@escaping (PHAsset)->())
}
