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
    @StateObject var vm = PhotoViewModel()
    
    @State private var size: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    @State var show = true
    @State var photosMode:PhotosFilter = .all
    @State private var scrollOffsetY: CGFloat = 0.0
    @State private var mainOffsetY: CGFloat = 0.0
    @State private var lastminY: CGFloat = .zero
    
    @State var image:UIImage?
    
    var imageList:[PHAsset]{
        switch photosMode{
        case .all,.other:
            return vm.assets
        case .bookmark:
            return vm.assets.filter({$0.isFavorite})
        }
    }
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
            if let asset = vm.fetchPhotosFirstAssets(mode:.all){
                vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.image = $0 }
            }
            size = CGSize(width: width()/numberOfColumns, height: width()/numberOfColumns)
        }
    }
    var imageListView:some View{
        ScrollView {
            VStack(spacing:0){
                let assetsItems =  Array(repeating: GridItem(.flexible(), spacing: 0), count: Int(numberOfColumns))
                assetControllView
                GeometryReader{ proxy in
                    let minY = proxy.frame(in: .global).minY
                    Color.clear
                        .onChange(of: minY) { value in
                                if abs(value - lastminY) > 10 {    //임계값 10으로 설정
                                    lastminY = value
                                    withAnimation {
                                        if lastminY < mainOffsetY {
                                            show = false
                                        } else if lastminY > mainOffsetY {
                                            show = true
                                        }
                                    }
                                }
                        }
                }.frame(height: 1)
                LazyVGrid(columns:assetsItems,spacing: 0){
                    ForEach(imageList, id: \.self) { asset in
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
                                        .shadow(radius: 1)
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
        }
        .overlay(alignment: .topLeading){
            VStack{
                headerView
                albumsListView
            }
            
        }
    }
    var headerView:some View{
        HStack{
            VStack(alignment: .leading){
                Text(photosMode == .other ? vm.album?.localizedTitle ?? "" : photosMode.rawValue)
                    .font(.largeTitle)
                Text("\(imageList.count)개의 항목")
            }
            .foregroundStyle(.white)
            .padding()
            .bold()
            Spacer()
            
        }
        .background(LinearGradient(colors: [.black.opacity(0.3),.clear], startPoint: .top, endPoint: .bottom))
        .allowsHitTesting(false)
    }
    
    var assetControllView:some View{
        GeometryReader{ geo in
            let minY = geo.frame(in: .global).minY
            Group{
                if let image{
                    Image(uiImage: image)
                        .resizable()
                       
                }else{
                    Color.gray.opacity(0.3)
                }
            }
            .overlay{
                Color.black.opacity(0.5)
                Color.clear
                    .background(Material.thin)
                    .overlay(alignment:.bottom){
                        LinearGradient(colors: [.clear,.black], startPoint: .top, endPoint: .bottom)
                            .frame(height: 30)
                    }
            }
            .offset(x:minY > 0 ? -minY/2 : 0,
                    y:minY > 0 ? -minY : 0)
            .frame(width: width() + (minY > 0 ? minY : 0),
                   height: (show ? height()/3  + 20: height()/6 + 20) + (minY > 0 ? minY: 0))
            .scaledToFill()
        }
        .padding(.bottom,(show ? height()/3 : height()/6) - 10)
        .environmentObject(vm)
    }
    
    var albumsListView:some View{
        func labelType(text:String) -> some View{
            Text(text)
                .font(.subheadline)
                .bold()
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 100)
        }
        return VStack{
            ScrollView(.horizontal,showsIndicators: false){
                if show{
                    HStack{
                        ForEach(PhotosFilter.allCases.filter{$0 != .other},id: \.self){ collection in
                            @State var assets:PHAsset?
                            Button {
                                photosMode = collection
                                vm.album = nil
                                vm.fetchAlbumAssets(from: nil)
                                if collection == .all{
                                    if let asset = vm.fetchPhotosFirstAssets(mode:.all){
                                        vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.image = $0 }
                                    }
                                }
                                else if collection == .bookmark{
                                    if let asset = vm.fetchPhotosFirstAssets(mode:.bookmark){
                                        vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.image = $0 }
                                    }
                                }else{
                                    self.image = nil
                                }
                            } label: {
                                VStack{
                                    if collection == .all{
                                        albumCategoryRow(assets: vm.fetchPhotosFirstAssets(mode:.all))
                                    }else if collection == .bookmark{
                                        albumCategoryRow(assets: vm.fetchPhotosFirstAssets(mode:.bookmark))
                                    }
                                    labelType(text:collection.rawValue)
                                }
                            }
                        }
                        ForEach(vm.albums, id: \.self) { collection in
                            Button {
                                photosMode = .other
                                vm.album = collection
                                vm.fetchAlbumAssets(from: collection)
                                if let asset = vm.fetchAlbumsFirstAssets(collection: collection){
                                    vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.image = $0 }
                                }else{
                                    self.image = nil
                                }
                            } label: {
                                VStack{
                                    albumCategoryRow(assets: vm.fetchAlbumsFirstAssets(collection: collection))
                                    labelType(text: collection.localizedTitle ?? "")
                                }
                            }
                        }
                    }.padding(.horizontal)
                }
            }
            GeometryReader{ proxy in
                Color.clear
                    .onAppear{
                        mainOffsetY = proxy.frame(in: .global).minY
                    }
                    .onChange(of: show) { _ in
                        mainOffsetY = proxy.frame(in: .global).minY - 30
                    }
            }
            .frame(height: 1)
        }
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
    
    private func albumCategoryRow(assets:PHAsset?) -> some View{
        Group{
            if let assets{
                PhotosItemView(assets: assets)
                    .scaledToFill()
            }else{
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: width()/3.5, height: width()/3.5)
        .clipped()
        .cornerRadius(5)
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
