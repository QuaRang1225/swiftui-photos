//
//  SourdeTypeFilter.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/10/24.
//

import Foundation
import Photos

enum SourceTypeFilter: String,CaseIterable {
    case userLibrary = "사용자 라이브러리"
    case sharedAlbum = "공유 앨범"
    case iCloudShared = "아이클라우드 공유"
    
    var code: UInt {
        switch self {
        case .userLibrary:
            return PHAssetSourceType.typeUserLibrary.rawValue
        case .sharedAlbum:
            return PHAssetSourceType.typeCloudShared.rawValue
        case .iCloudShared:
            return PHAssetSourceType.typeCloudShared.rawValue
        }
    }
}
