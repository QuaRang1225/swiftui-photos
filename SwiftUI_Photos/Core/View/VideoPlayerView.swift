//
//  VideoPlayerView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Binding var item: VideoPlayerItem?
    @State private var offset: CGSize = .zero

    var body: some View {
        VideoPlayer(player: item?.playerItem)
            .gesture(videoCloseGesture)
            .offset(offset)
            .progress(item?.playerItem == nil)
    }
    var videoCloseGesture:some Gesture{
        DragGesture()
            .onChanged { value in
                withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
                    self.offset = value.translation
                }
            }
            .onEnded { _ in
                withAnimation(.spring()){
                    if 50 < self.offset.height {
                        self.item = nil
                    }
                }
                withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
                    self.offset = .zero
                }
            }
    }
}

#Preview {
    VideoPlayerView(item: .constant(VideoPlayerItem(id: "", playerItem: AVPlayer())))
}
