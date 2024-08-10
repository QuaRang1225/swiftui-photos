//
//  AlbumList.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/11/24.
//

import Foundation
import Photos

struct AlbumListItem{
    var id:String
    var asset:PHAsset?
    var title:String
    var collection:PHAssetCollection
}
