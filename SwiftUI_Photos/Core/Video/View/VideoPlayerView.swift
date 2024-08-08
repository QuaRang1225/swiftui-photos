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
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging: Bool = false
    @State private var pause = false
    @State private var mode:PlayModeFilter = .normal
    @State private var volume: Float = 1.0
    @State private var speaker = false
    
    var body: some View {
        VStack{
            AVPlayerView(player: item?.playerItem)
                .itemCloseGesture(position: $offset){ self.item = nil }
                .overlay(alignment: .bottomTrailing,content: {speakerView})
            timeProgressionView
            optionsView
        }
        .progress(item?.playerItem == nil)
        .offset(offset)
        .onAppear {
            if let playerItem = item?.playerItem {
                playerItem.play()
                Task{
                    await setupTimeObserver()
                }
            }
        }
        .onTapGesture {
            withAnimation {
                speaker = false
            }
        }
    }
    ///현재 비디오의 진행 시간과 전체 길이를 감지해 업데이트
    ///비디오가 모두 재생되었으면 일시정지 모드 활성화
    private func setupTimeObserver() async {
        guard let playerItem = item?.playerItem else { return }
        
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        if let duration = try? await playerItem.currentItem?.asset.load(.duration){
            playerItem.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                let totalSeconds = CMTimeGetSeconds(duration)
                let currentSeconds = CMTimeGetSeconds(time)
                if !isDragging {
                    self.currentTime = currentSeconds
                    self.duration = totalSeconds
                    if self.currentTime == self.duration{
                        self.pause = true
                    }
                }
            }
        }
    }
    ///재생시간을 원하는 퍼센테이지(%)로 업데이트
    ///ex) 10초길이의 비디오는 6초로 이동하려면 seekToPerscentage(0.6)
    private func seekToPercentage(percentage: Double) async {
        guard let playerItem = item?.playerItem else { return }
        
        if let duration = try? await playerItem.currentItem?.asset.load(.duration){
            let totalSeconds = CMTimeGetSeconds(duration)
            let targetSeconds = totalSeconds * percentage
            
            let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: duration.timescale)
            await playerItem.seek(to: targetTime)
        }
    }
    ///재생시간을 원하는 시간으로 업데이트
    ///ex) 20초길이의 비디오는 10초로 이동 seekToTime(10)
    private func seekToTime(time: Double) async{
        guard let playerItem = item?.playerItem else { return }
        if let duration = try? await playerItem.currentItem?.asset.load(.duration){
            let targetTime = CMTime(seconds: time, preferredTimescale: duration.timescale)
            await playerItem.seek(to: targetTime)
        }
    }
    private var speakerView:some View{
        Button {
            withAnimation {
                speaker.toggle()
            }
        } label: {
            Image(systemName: "speaker.wave.3.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
        .overlay {
            if speaker{
                let value = Binding(get: { Double(volume) },set: { newValue in
                    volume = Float(newValue)
                    item?.playerItem.volume = volume // 볼륨 조절
                })
                Slider(value: value,in: 0...1)
                    .padding()
                    .background(Material.thin)
                    .cornerRadius(50)
                    .offset(x:130)
                    .frame(width: 200)
                    .rotationEffect(Angle(degrees: 270))
                    .accentColor(.black)
            }
        }.padding()
    }
    private var timeProgressionView:some View{
        HStack{
            Text(TimeInterval(floatLiteral: currentTime).timeFormatter())
            Slider(value: $currentTime,in: 0...duration){ isEditing in
                isDragging = isEditing
                if !isEditing {
                    Task{
                        await seekToTime(time: currentTime)
                    }
                }
            }
            Text("- " + TimeInterval(floatLiteral: duration - currentTime).timeFormatter())
        }
        .padding(.horizontal)
    }
    private var optionsView:some View{
        func modifier(image:some View,degrees:Double) -> some View{
            image
                .rotationEffect(Angle(degrees: degrees))
                .font(.largeTitle)
                .overlay {
                    Text("10")
                        .font(.system(size: 13))
                }.foregroundColor(.primary)
            
        }
        
        let playButton = Button{
            if currentTime == duration{
                Task{
                    await seekToPercentage(percentage: 0)
                    item?.playerItem.play()
                }
            }
            if pause{
                pause = false
                item?.playerItem.play()
            }else{
                pause = true
                item?.playerItem.pause()
            }
        } label: {
            Image(systemName: pause ? "play.fill" : "pause.fill")
                .bold()
                .font(.largeTitle)
                .foregroundColor(.primary)
        }
        .padding(.leading)
        
        let speeadOption = HStack{
            ForEach(PlayModeFilter.allCases,id: \.self){ mode in
                Button {
                    if currentTime == duration{
                        Task{
                            await seekToPercentage(percentage: 0)
                            item?.playerItem.play()
                        }
                    }
                    item?.playerItem.rate = mode.rate
                    self.mode = mode
                    self.pause = false
                } label: {
                    Image(systemName:mode.image)
                        .bold()
                        .font(.title)
                        .foregroundColor(self.mode == mode ? .black :.white)
                }
            }
        }
        .padding(7.5)
        .padding(.horizontal,5)
        .background{
            Capsule()
                .opacity(0.2)
        }
        
        let tenSecondsAgo = Button {
            Task{
                await seekToTime(time: currentTime-10)
            }
        } label: {
            let image = Image(systemName: "arrow.circlepath")
            modifier(image: image, degrees: 90)
        }
        
        let tenSecondsLater = Button {
            Task{
                await seekToTime(time: currentTime+10)
            }
        } label: {
            let image = Image(systemName: "arrow.circlepath").scaleEffect(x: -1, y: 1)
            modifier(image: image, degrees: 270)
        }
        return HStack{
            playButton
            speeadOption
            tenSecondsAgo
            tenSecondsLater
        }
    }
}

#Preview {
    VideoPlayerView(item: .constant(VideoPlayerItem(id: "", playerItem: AVPlayer())))
}

