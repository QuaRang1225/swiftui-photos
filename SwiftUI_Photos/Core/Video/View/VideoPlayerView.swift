//
//  VideoPlayerView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    var item: AVPlayer?
    @Binding var offset: CGSize
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDragging: Bool = false
    @State private var pause = false
    @State private var mode:PlayModeFilter = .normal
    @State private var volume: Float = 1.0
    @State private var speaker = false
    
    var body: some View {
        VStack{
            AVPlayerView(player: item)
                .overlay(alignment: .bottomTrailing,content: {speakerView})
            timeProgressionView
            optionsView
        }
        .progress(item == nil)
        .offset(offset)
        .onAppear {
            if let item{
                item.play()
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
        guard let item else { return }
        
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        if let duration = try? await item.currentItem?.asset.load(.duration){
            item.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
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
        guard let item else { return }
        
        if let duration = try? await item.currentItem?.asset.load(.duration){
            let totalSeconds = CMTimeGetSeconds(duration)
            let targetSeconds = totalSeconds * percentage
            
            let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: duration.timescale)
            await item.seek(to: targetTime)
        }
    }
    ///재생시간을 원하는 시간으로 업데이트
    ///ex) 20초길이의 비디오는 10초로 이동 seekToTime(10)
    private func seekToTime(time: Double) async{
        guard let item else { return }
        if let duration = try? await item.currentItem?.asset.load(.duration){
            let targetTime = CMTime(seconds: time, preferredTimescale: duration.timescale)
            await item.seek(to: targetTime)
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
                    item?.volume = volume // 볼륨 조절
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
                    item?.play()
                }
            }
            if pause{
                pause = false
                item?.play()
            }else{
                pause = true
                item?.pause()
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
                            item?.play()
                        }
                    }
                    item?.rate = mode.rate
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
    VideoPlayerView(item: AVPlayer(),offset: .constant(.zero))
}

