//
//  VideoPlayerItem.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import Foundation
import AVKit
import Photos

struct VideoPlayerItem: Identifiable {
    let id: String
    let asset:PHAsset
    var playerItem: AVPlayer
}
