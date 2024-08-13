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
    @State private var selectedAsset: AssetItem?   //
    @State private var position = CGSize.zero
    @Namespace private var namespace
    @StateObject var vm = PhotoViewModel()
    
    @State private var size: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    @State var show = true
    @State var photosMode:PhotosFilter = .all
    @State var photosModefilter:PhotosFilter = .all
    @State private var mainOffsetY: CGFloat = .zero
    @State private var lastminY: CGFloat = .zero
    
    @State var isFill = true
    @State var menu = false
    @State var image:UIImage?
    
    
    @State var selectedIndex:Int = 0
    
    var assetsItems:[GridItem]{
        Array(repeating: GridItem(.flexible(), spacing: 0), count: Int(numberOfColumns))
    }
    
    var body: some View {
        ZStack{
            imageListView
            SeleteAssetView(selectedAsset: $selectedAsset, selectedIndex: $selectedIndex, photosMode: $photosMode, show: $show, namespace: namespace)
            menuView
        }
        .progress(vm.progress)
        .userAllowAccessAlbum(vm.accessDenied)
        .gesture(gridAdjustmenGesture)
        .onAppear{
            if let asset = vm.fetchPhotosFirstAssets(mode:.all){
                vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.image = $0 }
            }
            size = CGSize(width: width()/numberOfColumns, height: width()/numberOfColumns)
        }
        .onChange(of: self.photosMode) { value in
            switch value{
            case .all,.other: break
            case .bookmark:
                vm.assetList = vm.assets.filter({$0.isFavorite})
            case .video:
                vm.assetList = vm.assets.filter{$0.mediaType == .video}
            case .photoScreenshot:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoScreenshot }
            case .photoLive:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoLive }
            case .photoHDR:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoHDR }
            case .photoPanorama:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoPanorama }
            case .photoDepthEffect:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoDepthEffect }
            case .videoStreamed:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .videoStreamed }
            case .videoCinematic:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .videoCinematic }
            case .videoTimelapse:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .videoTimelapse }
            case .videoHighFrameRate:
                vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .videoHighFrameRate }
            }
        }
        .environmentObject(vm)
    }
    var imageListView:some View{
        ScrollView {
            VStack(spacing:0){
                assetControllView
                GeometryReader{ proxy in
                    let minY = proxy.frame(in: .global).minY
                    LazyVGrid(columns:assetsItems,spacing: 0){
                        ForEach(vm.assetList.indices, id: \.self) { index in
                            let asset = vm.assetList[index]
                            Group{
                                if selectedAsset == nil{
                                    PhotosItemView(assets: .constant(asset))
                                        .aspectRatio(contentMode: isFill ? .fill : .fit)
                                        .frame(width: size.width, height: size.height)
                                        .clipShape(Rectangle())
                                        .contentShape(Rectangle())
                                        .allowsHitTesting(true)
                                        .matchedGeometryEffect(id: asset.localIdentifier, in: namespace)
                                        .overlay(alignment:.bottomTrailing){
                                            HStack{
                                                if asset.isFavorite{
                                                    Image(systemName: "heart.fill")
                                                }
                                                if asset.mediaType == .video{
                                                    Text(asset.duration.timeFormatter())
                                                }
                                            }
                                            .foregroundColor(.white)
                                            .shadow(color:.black.opacity(0.5),radius: 1)
                                            .padding(4)
                                        }
                                        .onTapGesture {
                                            vm.progress = true
                                            self.selectedIndex = index
                                            switch asset.mediaType{
                                            case .image:
                                                withAnimation(.spring(response: 0.25)) {
                                                    self.selectedAsset = AssetItem(asset: asset)
                                                }
                                            case .video:
                                                playVideo(asset: asset) { playerItem in
                                                    self.selectedAsset = AssetItem(asset: asset, playerItem: AVPlayer(playerItem: playerItem))
                                                }
                                            default: return
                                            }
                                        }
                                }
                                else{
                                    Color.clear
                                        .frame(width: size.width, height: size.height)
                                }
                            }
                            .transition(.move(edge: .bottom))
                        }
                    }
                    .onChange(of: minY) { value in
                        if abs(value - lastminY) > 15 {
                            withAnimation(.linear(duration:0.2)){
                                lastminY = value
                                if show,lastminY < mainOffsetY {
                                    show = false
                                } else if !show,lastminY > mainOffsetY {
                                    show = true
                                }
                            }
                        }
                    }
                }
                .frame(height: size.height * CGFloat(ceil(Double(vm.assetList.count)/3)))
            }
        }
        .overlay(alignment: .topLeading){
            VStack(spacing: 0){
                HStack{
                    headerView
                    Spacer()
                    if !show{
                        ratioView
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
    //제목 ---------
    var headerView:some View{
        HStack(alignment: .top){
            VStack(alignment: .leading){
                Text(photosMode == .other ? vm.album?.title ?? "알 수 없음" : photosMode.rawValue)
                    .font(.largeTitle)
                Text("\(vm.assetList.count)개의 항목")
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
                    .colorScheme(.dark)
                ScrollView(showsIndicators: false){
                    VStack{
                        let filter = PhotosFilter.allCases.filter{$0 != .all && $0 != .other}
                        Text("사진").font(.title).bold()
                        ForEach(filter.filter{$0.type == .photo},id: \.self){ filter in
                            Button {
                                self.photosMode = filter
                                self.photosModefilter = filter
                                menu = false
                            } label: {
                                HStack{
                                    Image(systemName: filter.image)
                                    Text(filter.rawValue)
                                }
                                
                                .padding(.vertical,15)
                            }
                        }
                        Text("비디오").font(.title).bold()
                        ForEach(filter.filter{$0.type == .video},id: \.self){ filter in
                            Button {
                                self.photosMode = filter
                                self.photosModefilter = filter
                                menu = false
                            } label: {
                                HStack{
                                    Image(systemName: filter.image)
                                    Text(filter.rawValue)
                                }
                                .padding(.vertical,15)
                            }
                        }
                    }.foregroundColor(.white)
                        .padding(.vertical,100)
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
            ratioView
            Button {
                withAnimation {
                    vm.isAsscending.toggle()
                    vm.fetchAlbumAssets(from: vm.album?.collection, condition: photosMode.predicate)
                    vm.fetchAlbums()
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
        return GeometryReader{ proxy in
            VStack{
                if show{
                    ScrollView(.horizontal,showsIndicators: false){
                        HStack{
                            Button {
                                photosMode = .all
                                vm.album = nil
                                vm.fetchAlbumAssets(from: nil, condition: nil)
                                if let asset = vm.fetchPhotosFirstAssets(mode:.all){
                                    vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.image = $0 }
                                }
                            } label: {
                                VStack{
                                    albumCategoryRow(assets: vm.fetchPhotosFirstAssets(mode:.all))
                                    labelType(text:PhotosFilter.all.rawValue)
                                }
                            }
                            ForEach(vm.albums,id: \.id) { album in
                                Button {
                                    photosMode = .other
                                    vm.album = album
                                    vm.fetchAlbumAssets(from: album.collection, condition: nil)
                                    if let asset = vm.fetchAlbumsFirstAssets(collection: album.collection){
                                        vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.image = $0 }
                                    }else{
                                        self.image = nil
                                    }
                                } label: {
                                    VStack{
                                        albumCategoryRow(assets: album.asset)
                                        labelType(text: album.title)
                                    }
                                }
                            }
                        }.padding(.horizontal)
                    }
                }
            }
            .onAppear{
                mainOffsetY = proxy.frame(in: .global).maxY
            }
            .onChange(of: show) { value in
                withAnimation {
                    if value{
                        mainOffsetY = proxy.frame(in: .global).maxY
                    }else{
                        mainOffsetY = lastminY
                    }
                }
            }
        }
        .frame(height: width()/3.5 + 20)
    }
    
    
//    private var imageItemView:some View{
//       
//    }
    
    
    
    
    
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
                PhotosItemView(assets: .constant(assets))
                    .scaledToFill()
            }
        }
        .frame(width: width()/3.5, height: width()/3.5)
        .clipped()
        .cornerRadius(5)
    }
    
    
    
    
}

#Preview {
    PhotosView()
        .environmentObject(PhotoViewModel())
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { }
}


