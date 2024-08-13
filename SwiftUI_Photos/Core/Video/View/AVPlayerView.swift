//
//  AVPlayerView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import Foundation
import AVKit
import SwiftUI

///**비디오 플레이어**
///
///- 커스텀으로 비디오의 재생,정지,볼륨을 조절하기 때문에 showsPlaybackControls를 사용하지 않기 위해 생성
///- 만약 showsPlaybackControls 기능을 비활성화 하지 않으려면 VideoPlayer 사용
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
