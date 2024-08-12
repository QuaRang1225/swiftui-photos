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
    @State var photosModefilter:PhotosFilter = .all
    @State private var mainOffsetY: CGFloat = .zero
    @State private var lastminY: CGFloat = .zero
    
    @State var isFill = true
    @State var menu = false
    @State var image:UIImage?
    
    @State var endOffset = CGSize.zero
    @State var currentOffset = CGSize.zero
    @State var mainCurrentScale:CGFloat = 1
    @State var endScale:CGFloat = 1
    @GestureState var changed = false
    
    @State var info = false
    @State var videoOffset:CGSize = .zero
    
    @State var adress:(country:String?, city:String?,district:String?)?
    @State var isMap = false
    
    @State var isFavorite = false
    
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
        .fullScreenCover(isPresented: $isMap){
            if let adress,let ci = adress.city,let co = adress.country,let di = adress.district{
                if let selectedAssets{
                    LocationMapView(buttonMode: false, annotions:  [City(asset: selectedAssets, country:co, city: ci, district: di, coordinate: selectedAssets.location ?? CLLocation(latitude: 1, longitude: 1))], dismiss: $isMap)
                }else if let asset = selectedVideo?.asset{
                    LocationMapView(buttonMode: false, annotions:  [City(asset: asset, country:co, city: ci, district: di, coordinate: asset.location ?? CLLocation(latitude: 1, longitude: 1))], dismiss: $isMap)
                }
            }
        }
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
                if selectedAssets == nil{
                    LazyVGrid(columns:assetsItems,spacing: 0){
                        ForEach(vm.assetList, id: \.self) { asset in
                            PhotosItemView(assets: asset)
                                .background(Color.white)
                                .aspectRatio(contentMode: isFill ? .fill : .fit)
                                .frame(width: size.width, height: size.height)
                                .clipShape(Rectangle()) // 원하는 모양으로 클리핑
                                .contentShape(Rectangle()) // 터치 영역을 클리핑된 영역으로 설정
                                .allowsHitTesting(true) // 터치 이벤트를 허용하는 설정
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
            ratioView.matchedGeometryEffect(id: "ratio", in: namespace)
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
        return VStack{
            ScrollView(.horizontal,showsIndicators: false){
                if show{
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
    
    
    private var imageItemView:some View{
        ZStack{
            Color.reversal
                .ignoresSafeArea()
                .opacity((selectedAssets == nil && selectedVideo == nil ) ? 0 : min(1, max(0, 1 - Double(position.height / 800))))
            VStack{
                if !info{
                    infoTextView
                }
                if let selectedAssets {
                    GeometryReader{ geo in
                        let g = geo.frame(in: .named("G"))
                        PhotosItemView(assets: selectedAssets)
                            .scaledToFit()
                            .frame(maxWidth: .infinity,maxHeight: .infinity)
                            .matchedGeometryEffect(id: selectedAssets.localIdentifier, in: namespace)
                            .onChange(of: changed) { change in
                                withAnimation(.easeIn(duration: 0.1)){
                                    if g.minX > 0{
                                        currentOffset.width = currentOffset.width - g.minX
                                    }
                                    if g.minY > 0{
                                        currentOffset.height = currentOffset.height - g.minY
                                    }
                                    if g.maxX < width(){
                                        currentOffset.width = g.minX - currentOffset.width
                                    }
                                    if g.maxY < width(){
                                        currentOffset.height = g.minY - currentOffset.height
                                    }
                                    if !change{
                                        endOffset = currentOffset
                                    }
                                }
                            }
                    }
                    .scaleEffect(mainCurrentScale)
                    .offset(currentOffset)
                    .simultaneousGesture(drag)
                    .simultaneousGesture(pinch)
                    .onTapGesture(count: 2) { // 더블 탭 감지
                        withAnimation {
                            if mainCurrentScale == 1{
                                mainCurrentScale = 2
                                endScale = 2
                            }else{
                                mainCurrentScale = 1
                                endScale = 1
                                currentOffset = .zero
                                endOffset = .zero
                            }
                        }
                    }
                    .coordinateSpace(name: "G")
                    .onAppear{
                        isFavorite = selectedAssets.isFavorite
                        vm.progress = false
                    }
                    if !info{
                        infoMenuView
                            .padding(30)
                            .matchedGeometryEffect(id: "info", in: namespace)
                    }
                }
                if let selectedVideo{
                    VideoPlayerView(item: $selectedVideo, offset: $videoOffset)
                        .gesture(videoDrag)
                        .onAppear{
                            isFavorite = selectedVideo.asset.isFavorite
                            vm.progress = false
                        }
                    if !info{
                        infoMenuView
                            .padding(30)
                            .matchedGeometryEffect(id: "info", in: namespace)
                    }
                    
                }
                if info{
                    if let selectedAssets{
                        infoView(asset:selectedAssets)
                    }
                    else if let selectedVideo{
                        infoView(asset:selectedVideo.asset)
                    }
                }
                
            }
        }
    }
    
    func infoView(asset:PHAsset) -> some View{
        VStack(alignment:.leading,spacing:10){
            Text("\(MediaTypeFilter.allCases.first(where: {$0.code == asset.mediaType.rawValue})?.rawValue ?? "")")
                .font(.title2)
                .bold()
                .padding(.bottom,5)
            Text("\(asset.localIdentifier)").opacity(0.5)
            HStack{
                if asset.representsBurst{
                    Text("Burst")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(2.5)
                        .padding(.horizontal,2.5)
                        .background {
                            Color.gray.opacity(0.5)
                                .cornerRadius(2)
                        }
                }
                if asset.hasAdjustments{
                    Text("Edited")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(2.5)
                        .padding(.horizontal,2.5)
                        .background {
                            Color.gray.opacity(0.5)
                                .cornerRadius(2)
                        }
                }
            }
            HStack{
                Spacer()
                Text("\(asset.pixelWidth.removeCommas()) x \(asset.pixelHeight.removeCommas())")
                    .opacity(0.5)
                Text("\(SourceTypeFilter.allCases.first(where: {$0.code == asset.sourceType.rawValue})?.rawValue ?? "")")
            }
            HStack{
                Text("원본").bold()
                Spacer()
                Text("\(asset.creationDate.formattedDate())")
            }
            HStack{
                Text("수정").bold()
                Spacer()
                Text("\(asset.modificationDate.formattedDate())")
            }
            if let adress,let ci = adress.city,let co = adress.country,let di = adress.district{
                Button {
                    isMap = true
                } label: {
                    VStack(spacing: 0){
                        LocationMapView(buttonMode: true, annotions: [City(asset: asset, country:co, city: ci, district: di, coordinate: asset.location ?? CLLocation(latitude: 1, longitude: 1))], dismiss: .constant(false))
                            .frame(height: 150)
                            .allowsHitTesting(false)
                        HStack{
                            if let c = adress.city,let d = adress.district{
                                Text("\(c) - \(d)").foregroundColor(.blue)
                            }else{
                                Text("미확인 구역").foregroundColor(.blue)
                            }
                            Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5))
                            Spacer()
                        }
                        .font(.subheadline)
                        .padding(10)
                        .background(Color.gray.opacity(0.5))
                    }
                    .cornerRadius(5)
                }
            }
            if info{
                infoMenuView
                    .matchedGeometryEffect(id: "info", in: namespace)
            }
        }
        .padding()
        .background{
            VStack(spacing:0){
                Divider()
                Color.gray.opacity(0.1).ignoresSafeArea()
            }.shadow(radius: 10)
        }
        .onAppear{
            Task{
                if let adress = await asset.location?.fetchAddress(){
                    self.adress = adress
                }
            }
        }
        .gesture(DragGesture().onEnded({ gesture in
            if gesture.translation.height > 0{
                withAnimation {
                    self.info = false
                }
            }
        }))
    }
    var infoTextView:some View{
        HStack{
            if let selectedAssets{
                VStack(alignment: .leading){
                    let date = selectedAssets.creationDate.formattedTitleDate()
                    Text(date.date)
                        .font(.title)
                    Text(date.time)
                        .font(.subheadline)
                        .opacity(0.8)
                }.bold()
                Spacer()
                Button {
                    withAnimation {
                        self.selectedAssets = nil
                    }
                    
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                }
            }
            if let asset = selectedVideo?.asset{
                VStack(alignment: .leading){
                    let date = asset.creationDate.formattedTitleDate()
                    Text(date.date)
                        .font(.title)
                    Text(date.time)
                        .font(.subheadline)
                        .opacity(0.8)
                }.bold()
                Spacer()
                Button {
                    withAnimation {
                        self.selectedVideo = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
    }
    func fetchImage(from asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = true
        
        imageManager.requestImage(for: asset,
                                  targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                                  contentMode: .aspectFill,
                                  options: imageRequestOptions) { image, _ in
            completion(image)
        }
    }
    
    // URL로 변환 (비디오)
    func fetchVideoURL(from asset: PHAsset, completion: @escaping (URL?) -> Void) {
        let videoManager = PHImageManager.default()
        let videoRequestOptions = PHVideoRequestOptions()
        
        videoManager.requestAVAsset(forVideo: asset, options: videoRequestOptions) { avAsset, audioMix, _ in
            if let asset = avAsset as? AVURLAsset {
                completion(asset.url)
            } else {
                completion(nil)
            }
        }
    }
    private func shareMedia(image:UIImage?,videoURL:URL?) {
        var items: [Any] = []
        
        if let image{
            items.append(image)
        }
        
        if let videoURL {
            items.append(videoURL)
        }
        
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let rootController = windowScene.windows.first?.rootViewController {
                    rootController.present(activityController, animated: true, completion: nil)
                }
            }
        }
    }
    var infoMenuView:some View{
        HStack{
            Button {
                if let selectedAssets {
                    fetchImage(from: selectedAssets) { img in
                        shareMedia(image: img, videoURL: nil)
                    }
                } else if let asset = selectedVideo?.asset {
                    fetchVideoURL(from: asset) { url in
                        shareMedia(image: nil, videoURL: url)
                    }
                }
            } label: {
                Image(systemName:"square.and.arrow.up")
                    .padding(10)
                    .background{
                        Color.reversal
                        Color.gray.opacity(0.2)
                    }
                    .clipShape(Circle())
                
            }
            Spacer()
            HStack{
                Button {
                    if let selectedAssets {
                        DispatchQueue.global().async {
                            vm.assetavorite(asset: selectedAssets,isFavorite:isFavorite){ asset,favorite  in
                                isFavorite = favorite
                                if let index = vm.assetList.firstIndex(where: {$0 == selectedAssets}),let asset{
                                    DispatchQueue.main.async {
                                        withAnimation {
                                            if photosMode == .bookmark{
                                                vm.assetList = vm.assetList.filter{$0 != asset}
                                            }else{
                                                vm.assetList[index] = asset
                                            }
                                            vm.assets = vm.assetList
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if let asset = selectedVideo?.asset {
                        DispatchQueue.global().async {
                            vm.assetavorite(asset: asset,isFavorite:isFavorite){ asset,favorite  in
                                isFavorite = favorite
                                if let index = vm.assetList.firstIndex(where: {$0 == asset}),let asset{
                                    DispatchQueue.main.async {
                                        withAnimation {
                                            if photosMode == .bookmark{
                                                vm.assetList = vm.assetList.filter{$0 != asset}
                                            }else{
                                                vm.assetList[index] = asset
                                            }
                                            vm.assets = vm.assetList
                                        }
                                       
                                    }
                                }
                            }
                        }
                    }
                    
                } label: {
                    Image(systemName:isFavorite ? "heart.fill" : "heart")
                }
                .padding(.trailing,30)
                Button {
                    withAnimation {
                        info.toggle()
                    }
                } label: {
                    Image(systemName:!info ? "info.circle" : "info.circle.fill")
                }
                Button {
                    
                } label: {
                    Image(systemName:"crop.rotate")
                }
                .padding(.leading,30)
            }
            .padding(10)
            .background{
                Color.reversal
                Color.gray.opacity(0.2)
            }
            .clipShape(Capsule())
            
            Spacer()
            Button {
                if let selectedAssets {
                    vm.deleteAssetLibrary(asset: selectedAssets) { asset in
                        DispatchQueue.main.async {
                            withAnimation {
                                vm.assetList = vm.assetList.filter{$0 != asset}
                                vm.assets = vm.assetList
                                self.selectedAssets = nil
                                self.show = false
                                vm.fetchAlbums()
                            }
                        }
                    }
                }
                if let asset = selectedVideo?.asset {
                    vm.deleteAssetLibrary(asset: asset) { asset in
                        DispatchQueue.main.async {
                            withAnimation {
                                vm.assetList = vm.assetList.filter{$0 != asset}
                                vm.assets = vm.assetList
                                self.selectedVideo = nil
                                self.show = false
                                vm.fetchAlbums()
                            }
                        }
                    }
                }
            } label: {
                Image(systemName:"trash")
                    .padding(10)
                    .background{
                        Color.reversal
                        Color.gray.opacity(0.2)
                    }
                    .clipShape(Circle())
            }
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
                        selectedVideo = VideoPlayerItem(id: id, asset: asset, playerItem: AVPlayer(playerItem: playerItem))
                    }
                }
            }
        }
    }
    var videoDrag:some Gesture{
        DragGesture()
            .onChanged { gesture in
                if gesture.translation.height < 20{
                    withAnimation {
                        self.info = true
                    }
                }
            }
            .onEnded { gesture in
                if gesture.translation.height > 20{
                    withAnimation {
                        if info{
                            self.info = false
                        }else{
                            self.selectedVideo = nil
                        }
                    }
                }
            }
    }
    var drag:some Gesture{
        DragGesture()
            .updating($changed){ _,changed,_ in
                if mainCurrentScale != 1{
                    changed = true
                }
            }
            .onChanged{ gesture in
                if mainCurrentScale != 1{
                    currentOffset = endOffset + gesture.translation
                }else{
                    if gesture.translation.height < 0{
                        withAnimation {
                            self.info = true
                        }
                    }
                }
            }
            .onEnded { gesture in
                if mainCurrentScale == 1{
                    if gesture.translation.height > 0{
                        withAnimation {
                            if info{
                                self.info = false
                            }else{
                                self.selectedAssets = nil
                            }
                        }
                    }
                }
            }
    }
    var pinch:some Gesture{
        MagnificationGesture()
            .updating($changed){ _,changed,_ in
                changed = true
            }
            .onChanged { gesture in
                mainCurrentScale = min(max(gesture + endScale - 1, 1), 3)
            }
            .onEnded { gesture in
                withAnimation(.easeIn(duration: 0.1)){
                    endScale = min(max(endScale + gesture - 1, 1), 3)
                    if endScale < 1 {
                        mainCurrentScale = 1
                        endScale = 1
                        currentOffset = .zero
                        endOffset = .zero
                    }
                }
            }
        
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


