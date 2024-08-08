//
//  ImageListView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import SwiftUI
import Photos

struct PhotosView: View {
    
    @State private var numberOfColumns: CGFloat = 3
    @State private var selectedAssets: PHAsset?
    @State private var selectedVideo: VideoPlayerItem?
    @State private var position = CGSize.zero
    @Namespace private var namespace
    @EnvironmentObject var vm:PhotoViewModel
    
    @State private var size: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        
        ZStack{
            imageListView
            imageItemView
        }
        .environmentObject(vm)
        .progress(vm.progress)
        .userAllowAccessAlbum(vm.accessDenied)
        .gesture(gridAdjustmenGesture)
        .onAppear{
            size = CGSize(width: width()/numberOfColumns, height: width()/numberOfColumns)
        }
    }
    var imageListView:some View{
        ScrollView {
            let assetsItems =  Array(repeating: GridItem(.flexible(), spacing: 0), count: Int(numberOfColumns))
            LazyVGrid(columns:assetsItems,spacing: 0){
                ForEach(vm.assets, id: \.self) { asset in
                    PhotosItemView(assets: asset)
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipShape(Rectangle()) // 원하는 모양으로 클리핑
                        .contentShape(Rectangle()) // 터치 영역을 클리핑된 영역으로 설정
                        .allowsHitTesting(true) // 터치 이벤트를 허용하는 설정
                        .matchedGeometryEffect(id: asset.localIdentifier, in: namespace)
                        .overlay(alignment:.bottomTrailing){
                            if asset.mediaType == .video{
                                Text(asset.duration.timeFormatter())
                                    .padding(2)
                            }
                        }
                        .onTapGesture {
                            switch asset.mediaType{
                            case .image:
                                withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
                                    selectedAssets = asset
                                }
                            case .video: playVideo(asset:asset,id:asset.localIdentifier)
                            default: return
                            }
                        }
                }
            }
        }
        .navigationBarTitle("갤러리")
    }
    @ViewBuilder
    private var imageItemView:some View{
        Color.black
            .ignoresSafeArea()
            .opacity((selectedAssets == nil && selectedVideo == nil ) ? 0 : min(1, max(0, 1 - abs(Double(position.height) / 800))))
        if let selectedAssets {
            PhotosItemView(assets: selectedAssets)
                .scaledToFit()
                .matchedGeometryEffect(id: selectedAssets.localIdentifier, in: namespace)
                .offset(position)
                .itemCloseGesture(position: $position) {self.selectedAssets = nil}
        }
        if selectedVideo != nil{
            VideoPlayerView(item: $selectedVideo)
        }
    }
    
    private var gridAdjustmenGesture:some Gesture{
        MagnificationGesture()
            .onChanged { value in
                withAnimation(.spring()){
                    self.currentScale = value.magnitude
                    let scaleDifference = self.currentScale / self.lastScale
                    if scaleDifference > 1.2 {
                        if numberOfColumns > 1 {
                            numberOfColumns -= 1
                        }
                        self.lastScale = self.currentScale
                    } else if scaleDifference < 0.8 {
                        if numberOfColumns < 5 {
                            numberOfColumns += 1
                        }
                        self.lastScale = self.currentScale
                    }
                    size = CGSize(width: UIScreen.main.bounds.width / CGFloat(numberOfColumns), height: UIScreen.main.bounds.width / CGFloat(numberOfColumns))
                }
            }
            .onEnded { _ in
                withAnimation(.spring()){
                    self.lastScale = 1.0
                }
            }
    }
    private func playVideo(asset: PHAsset,id:String){
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { playerItem, _ in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
                    if let playerItem {
                        selectedVideo = VideoPlayerItem(id: id, playerItem: AVPlayer(playerItem: playerItem))
                    }
                }
            }
        }
    }
}

#Preview {
    PhotosView()
        .environmentObject(PhotoViewModel())
}
