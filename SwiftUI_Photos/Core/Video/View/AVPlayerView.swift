//
//  AVPlayerView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import Foundation
import AVKit
import SwiftUI

struct AVPlayerView : UIViewControllerRepresentable {
    var player : AVPlayer?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}
