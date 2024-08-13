//
//  VideoPlayerView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import SwiftUI
import AVKit
import Photos

///비디오 재생뷰
///
///- Asset이 비디오 타입일 때 실행되는 뷰
///- 진행 상태 및 진행시간 확인 및 컨트롤 가능
///- 재생 상태 컨트롤 가능
struct VideoPlayerView: View {
    var item: AVPlayer?
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
                .overlay(alignment: .bottomTrailing,content: { speakerView })
            VStack{
                timeProgressionView
                optionsView
            }
            .padding(.vertical)
            .background(Color.gray.opacity(0.2))
        }
        .progress(item == nil)
        .onAppear(perform: initializer)
        .onTapGesture {
            withAnimation { speaker = false }
        }
    }
    
}

#Preview {
    VideoPlayerView(item: AVPlayer())
}

extension VideoPlayerView{
    //Method--------------------------------------------------------------------------------------------------
    ///**재생시간을 슬라이더에 업데이트**
    ///
    ///- 현재 비디오의 진행 시간과 전체 길이를 감지해 업데이트
    ///- 비디오가 모두 재생되었으면 일시정지 모드 활성화
    private func setupTimeObserver() async {
        guard let item else { return }
        
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        guard let duration = try? await item.currentItem?.asset.load(.duration) else { return }
            item.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                let totalSeconds = CMTimeGetSeconds(duration)
                let currentSeconds = CMTimeGetSeconds(time)
                guard !isDragging else { return }
                self.currentTime = currentSeconds
                self.duration = totalSeconds
                guard self.currentTime == self.duration else{ return }
                self.pause = true
            }
    }
    ///**슬라이더로 재생시간 컨트롤**
    ///
    ///- 재생시간을 원하는 퍼센테이지(%)로 업데이트
    ///- ex) 10초길이의 비디오는 6초로 이동하려면 seekToPerscentage(0.6)
    private func seekToPercentage(percentage: Double) async {
        guard let item else { return }
        
        guard let duration = try? await item.currentItem?.asset.load(.duration) else {return}
        let totalSeconds = CMTimeGetSeconds(duration)
        let targetSeconds = totalSeconds * percentage
        
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: duration.timescale)
        await item.seek(to: targetTime)
    }
    ///**10초 전/후 컨트롤**
    ///
    ///- 재생시간을 원하는 시간으로 업데이트
    ///- ex) 20초길이의 비디오는 10초로 이동 seekToTime(10)
    private func seekToTime(time: Double) async{
        guard let item else { return }
        if let duration = try? await item.currentItem?.asset.load(.duration){
            let targetTime = CMTime(seconds: time, preferredTimescale: duration.timescale)
            await item.seek(to: targetTime)
        }
    }
    ///**생성자**
    ///
    ///- 영상이 나타날때 바로 재생
    private func initializer(){
        guard let item else { return }
        item.play()
        Task{ await setupTimeObserver() }
    }
    //View--------------------------------------------------------------------------------------------------
    
    ///**볼륨**
    ///
    ///- 볼륨을 조절할 수 있는 뷰
    ///- 다른 곳을 터치 시 볼륨창이 사라짐
    @ViewBuilder
    private var speakerView:some View{
        Button { withAnimation { speaker.toggle() }
        } label: {
            Image(systemName: "speaker.wave.3.fill")
                .font(.title3)
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
        .overlay {
            let value =  Binding(get: {
                Double(volume) },set: { newValue in
                volume = Float(newValue)
                item?.volume = volume
            })
            Slider(value: value,in: 0...1)
                .padding()
                .background(Material.thin)
                .cornerRadius(50)
                .offset(x:130)
                .frame(width: 200)
                .rotationEffect(Angle(degrees: 270))
                .accentColor(.black)
                .show(speaker)
        }.padding()
    }
    ///**시간 진행바**
    ///
    ///- 현재 비디오가 얼마나 재생됐는지 확인과 직접 진행상태를 컨트롤할 수 있는 뷰
    @ViewBuilder
    private var timeProgressionView:some View{
        HStack{
            Text(TimeInterval(floatLiteral: currentTime).timeFormatter())
            Slider(value: $currentTime,in: 0...duration){ isEditing in
                isDragging = isEditing
                guard !isEditing else{ return }
                Task{ await seekToTime(time: currentTime) }
            }
            Text("- " + TimeInterval(floatLiteral: duration - currentTime).timeFormatter())
        }
        .padding(.horizontal)
    }
    ///**비디오 컨트롤 뷰**
    ///
    ///- 재생 및 일시정지
    ///- 빨리감기 및 되감기
    ///- 앞으로 혹은 뒤로 10초 점프
    @ViewBuilder
    private var optionsView:some View{
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
        }
        
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
                        .font(.title2)
                        .foregroundColor(self.mode == mode ? .black :.white)
                }
            }
        }
        .padding(5)
        .padding(.horizontal,5)
        .background{ Capsule().opacity(0.2) }
        let tenSecondsAgo = Button {
            Task{ await seekToTime(time: currentTime-10) }
        } label: {
            Image(systemName:"goforward.10")
        }
        
        let tenSecondsLater = Button {
            Task{ await seekToTime(time: currentTime+10) }
        } label: {
            Image(systemName:"goforward.10")
        }
        HStack{
            playButton
            tenSecondsAgo
            tenSecondsLater
            Spacer()
            speeadOption
        }
        .font(.title)
        .foregroundColor(.primary)
        .padding(.horizontal)
    }
}
