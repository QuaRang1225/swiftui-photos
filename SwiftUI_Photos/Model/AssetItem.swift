//
//  VideoPlayerItem.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import Foundation
import AVKit
import Photos

struct AssetItem: Identifiable {
    let id: String
    var asset:PHAsset
    var playerItem: AVPlayer?
    
    init(asset: PHAsset, playerItem: AVPlayer? = nil) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.playerItem = playerItem
    }
    
}
