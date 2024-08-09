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
    @State private var mainOffsetY: CGFloat = .zero
    @State private var lastminY: CGFloat = .zero
    
    @State var isFill = true
    @State var menu = false
    @State var image:UIImage?
    
    var imageList:[PHAsset]{
        switch photosMode{
        case .all,.other:
            return vm.assets
        case .bookmark:
            return vm.assets.filter({$0.isFavorite})
        case .video:
            return vm.assets.filter{$0.mediaType == .video}
        case .photoScreenshot:
            return vm.assets.filter{ $0.mediaSubtypes == .photoScreenshot }
        case .photoLive:
            return vm.assets.filter{ $0.mediaSubtypes == .photoLive }
        case .photoHDR:
            return vm.assets.filter{ $0.mediaSubtypes == .photoHDR }
        case .photoPanorama:
            return vm.assets.filter{ $0.mediaSubtypes == .photoPanorama }
        case .photoDepthEffect:
            return vm.assets.filter{ $0.mediaSubtypes == .photoDepthEffect }
        case .videoStreamed:
            return vm.assets.filter{ $0.mediaSubtypes == .videoStreamed }
        case .videoCinematic:
            return vm.assets.filter{ $0.mediaSubtypes == .videoCinematic }
        case .videoTimelapse:
            return vm.assets.filter{ $0.mediaSubtypes == .videoTimelapse }
        case .videoHighFrameRate:
            return vm.assets.filter{ $0.mediaSubtypes == .videoHighFrameRate }
        }
    }
    var body: some View {
        ZStack{
            imageListView
            imageItemView
            menuView
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
                            if abs(value - lastminY) > 15 {    //임계값 10으로 설정
                                lastminY = value
                                withAnimation {
                                    if show,lastminY < mainOffsetY {
                                        show = false
                                    } else if !show,lastminY > mainOffsetY {
                                        show = true
                                    }
                                }
                            }
                        }
                }
                .frame(height: 1)
                LazyVGrid(columns:assetsItems,spacing: 0){
                    ForEach(imageList, id: \.self) { asset in
                        PhotosItemView(assets: asset)
                            .background(Color.white)
                            .aspectRatio(contentMode: isFill ? .fill : .fit)
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
            VStack(spacing: 0){
                HStack{
                    headerView
                    Spacer()
                    if !show{
                        ratioView
                            .matchedGeometryEffect(id: "ratio", in: namespace)
                            .padding()
                    }
                    if show{
                        Button {
                            withAnimation {
                                menu.toggle()
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
                .background(LinearGradient(colors: [.black.opacity(0.3),.clear], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
                if show{
                    optionCategoryView
                }
                albumsListView
            }
        }
    }
    var headerView:some View{
        HStack(alignment: .top){
            VStack(alignment: .leading){
                Text(photosMode == .other ? vm.album?.localizedTitle ?? "" : photosMode.rawValue)
                    .font(.largeTitle)
                Text("\(imageList.count)개의 항목")
            }
            .foregroundStyle(.white)
            
            .bold()
            Spacer()
            
        }
        .padding()
        
        .allowsHitTesting(false)
        
    }
    var menuView:some View{
        ZStack{
            if menu{
            Color.clear
                .background(Material.thin)
                ScrollView(showsIndicators: false){
                    VStack{
                        ForEach(PhotosFilter.allCases.filter{$0 != .all && $0 != .other},id: \.self){ filter in
                            Button {
                                self.photosMode = filter
                                menu = false
                            } label: {
                                HStack{
                                    Image(systemName: filter.image)
                                    Text(filter.rawValue)
                                }
                                .foregroundColor(.white)
                                .padding(.vertical,15)
                            }
                        }
                    }
                    .padding(.top,100)
                }
            }
        }
        .onTapGesture {
            withAnimation {
                menu.toggle()
            }
        }
    }
    var ratioView:some View{
        Button {
            withAnimation {
                isFill.toggle()
            }
        } label: {
            VStack{
                Image(systemName: isFill ? "arrow.down.forward.and.arrow.up.backward.square":"arrow.down.backward.and.arrow.up.forward.square")
                    .font(.title3)
                    .padding(10)
                    .background(Circle().foregroundColor(.gray))
                Text("비율")
                    .shadow(radius: 1)
                    .font(.caption)
            }
            .foregroundColor(.white)
        }
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
                        LinearGradient(colors: [.clear,.reversal], startPoint: .top, endPoint: .bottom)
                            .frame(height: 30)
                    }
            }
            .offset(x:minY > 0 ? -minY/2 : 0,
                    y:minY > 0 ? -minY : 0)
            .frame(width: width() + (minY > 0 ? minY : 0),
                   height: (show ? height()/2.5  + 20: height()/6 + 20) + (minY > 0 ? minY: 0))
            .scaledToFill()
        }
        .padding(.bottom,(show ? height()/2.5 : height()/6) - 10)
    }
    var optionCategoryView:some View{
        HStack{
            ratioView.matchedGeometryEffect(id: "ratio", in: namespace)
            Button {
                withAnimation {
                    vm.isAsscending.toggle()
                    vm.fetchAlbumAssets(from: vm.album)
                    show = false
                }
            } label: {
                VStack{
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.title3)
                        .padding(10)
                        .background(Circle().foregroundColor(.gray))
                    Text(vm.isAsscending ? "과거순":"최신순")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            Spacer()
        }
        .padding([.horizontal,.bottom])
    }
    var albumsListView:some View{
        func labelType(text:String) -> some View{
            Text(text)
                .font(.subheadline)
                .bold()
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 100)
        }
        return VStack{
            ScrollView(.horizontal,showsIndicators: false){
                if show{
                    HStack{
                            Button {
                                photosMode = .all
                                vm.album = nil
                                vm.fetchAlbumAssets(from: nil)
                                if let asset = vm.fetchPhotosFirstAssets(mode:.all){
                                    vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.image = $0 }
                                }
                            } label: {
                                VStack{
                                    albumCategoryRow(assets: vm.fetchPhotosFirstAssets(mode:.all))
                                    labelType(text:PhotosFilter.all.rawValue)
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
                    .onChange(of: show) { value in
                        withAnimation {
                            if value{
                                mainOffsetY = proxy.frame(in: .global).minY
                            }else{
                                mainOffsetY = lastminY
                            }
                        }
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
        ZStack{
            Color.white
            Color.gray.opacity(0.3)
            if let assets{
                PhotosItemView(assets: assets)
                    .scaledToFill()
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
