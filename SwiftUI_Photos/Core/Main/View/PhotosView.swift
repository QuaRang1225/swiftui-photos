//
//  ImageListView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import SwiftUI
import Photos

struct PhotosView: View {
    
    ///선택한 항목
    @State private var selectedAsset: AssetItem?
    ///선택한 항목의 index
    @State private var selectedIndex:Int = 0
    ///현재 항목의 리스트 모드
    @State var photosMode:PhotosFilter = .all
    
    
    ///그리드 칸수
    @State private var numberOfColumns: CGFloat = 3
    ///각 그리드 아이템 사이즈
    @State private var gridItemSize: CGSize = .zero
    ///그리드 아이템 사이징을 위한 상태변수
    ///- 변화량에 사용되며 사이징이 끝나면 항상 1로 초기화됨
    @State private var lastScale: CGFloat = 1.0
    
    
    ///앨범리스트 show/hide를 하기위한 상단부터의 offset
    @State private var mainOffsetY: CGFloat = .zero
    ///mainOffsetY를 계산하기 위한 상태변수
    ///- 앨범리스트가 show/hide됨에 따라 lastminY이 달라짐
    @State private var lastminY: CGFloat = .zero
    
    ///앨범 리스트
    ///- true : show
    ///- false : hide
    @State var show = true
    ///항목 아이템의 비율 fill/fit
    ///- true : fill
    ///- false : fit
    @State var isFill = true
    ///항목 카테고리 메뉴
    ///- true : show
    ///- false : hide
    @State var menu = false
    
    
    
    ///뷰 연동을 위한 namespace
    ///- 항목 썸네일 <-> 항목 뷰
    @Namespace private var namespace
    ///헤더 뷰 background
    @State var backgroundImage:UIImage?
    /// ViewModel
    @StateObject var vm = PhotoViewModel()
    
    ///그리드 아이템 배열
    var assetsItems:[GridItem]{
        Array(repeating: GridItem(.flexible(), spacing: 0), count: Int(numberOfColumns))
    }
    
    var body: some View {
        ZStack{
            assetListView
            SeleteAssetView(selectedAsset: $selectedAsset, selectedIndex: $selectedIndex, photosMode: $photosMode, show: $show, namespace: namespace)
            categoryMenuView
        }
        .progress(vm.progress)
        .userAllowAccessAlbum(vm.accessDenied)
        .onAppear(perform: initializer)
        .onChange(of: self.photosMode){ updateListEvent(value: $0) }
        .gesture(gridAdjustmenGesture)
        .environmentObject(vm)
    }
    
    //Container--------------------------------------------------------------------------------------------------
    ///**항목 리스트**
    ///
    ///- 사용자 갤러리에 존재하는 모든 항목을 리스트로 반환하는 뷰
    ///
    ///## 옵션
    ///- 전체항목
    ///- 즐겨찾기 항목
    ///- 사진 및 비디오 서브타입
    ///- 앨범 리스트 항목
    @ViewBuilder
    private var assetListView:some View{
        ScrollView(){
            VStack(spacing:0){
                backgroundView
                GeometryReader{ proxy in
                    let minY = proxy.frame(in: .global).minY
                    LazyVGrid(columns:assetsItems,spacing: 0){
                        ForEach(vm.assetList.indices, id: \.self) { index in
                            let asset = vm.assetList[index]
                            assetItemsRowView(asset: asset,index:index)
                        }
                    }
                    .onChange(of: minY){ scrollEvent(value: $0) }
                }
                .frame(height: gridItemSize.height * CGFloat(ceil(Double(vm.assetList.count)/3)))
            }
        }
        .overlay(alignment: .topLeading){ headerControllView }
    }
    ///**항목 카테고리 타입 별 리스트 뷰**
    ///
    ///- 미디어 타입에 따라 이미지 혹은 비디오 카테고리 리스트 반환
    @ViewBuilder
    private func categoryListView(list:[PhotosFilter]) -> some View{
        ForEach(list,id: \.self){ filter in
            Button {
                self.photosMode = filter
                menu = false
            } label: {
                HStack{
                    Image(systemName: filter.image)
                    Text(filter.rawValue)
                }
                .padding(.vertical,15)
            }
        }
    }
    ///**항목 카테고리 리스트 뷰**
    ///
    ///- 사진 : 즐겨 찾기/스크린샷/Live Photo 등
    ///- 비디오 : 스트리밍/시네마틱/타임랩스 등
    @ViewBuilder
    private var categoryMenuView:some View{
        ZStack{
            Color.clear
                .background(Material.thin)
                .colorScheme(.dark)
            ScrollView(showsIndicators: false){
                VStack{
                    let list = PhotosFilter.allCases.filter{$0 != .all && $0 != .other}
                    Text("사진").font(.title).bold()
                    categoryListView(list: list.filter{$0.type == .photo})
                    Text("비디오").font(.title).bold()
                    categoryListView(list: list.filter{$0.type == .video})
                }.foregroundColor(.white)
                    .padding(.vertical,100)
            }
        }
        .onTapGesture {
            withAnimation {
                menu.toggle()
            }
        }
        .show(menu)
    }
    ///**백그라운드 뷰**
    ///
    ///- 현재 보고 있는 앨범의 첫 화면을 백그라운드로 설정
    @ViewBuilder
    private var backgroundView:some View{
        BlurBackGround(height: show ? height()/2.5 : height()/6) {
            Group{
                if let backgroundImage{
                    Image(uiImage: backgroundImage)
                        .resizable()
                }
            }
        }
    }
    ///**사진 보기 옵션**
    ///
    ///- 아이템 비율 기능 (``ratioView``)
    ///- 정렬 기능 (과거순,최신순)
    @ViewBuilder
    private var optionCategoryView:some View{
        HStack{
            ratioView
            CustomButton(image: "arrow.up.arrow.down", text: vm.isAsscending ? "과거순":"최신순", buttonColor: .gray, imageColor: .white) {
                withAnimation {
                    vm.isAsscending.toggle()
                    vm.fetchAlbumAssets(from: vm.album?.collection, condition: photosMode.predicate)
                    vm.fetchAlbums()
                    show = false
                }
            }
            Spacer()
        }
        .padding([.horizontal,.bottom])
    }
    ///**앨범 리스트**
    ///
    ///- 전체 항목과 사용자 앨범리스트를 캐러셀형태로 구현되어있는 뷰
    ///- 각 버튼은 photosMode를 변경해 전체 앨범 리스트를 업데이트하고 앨범정보를 표시하기 위래 PhotoViewModel에 album 상태변수를 업데이트
    ///- 현재 앨범 항목 선택에 따라 backgroud 이미지 업데이트 만약 이미지가 없을 경우 nil 저장
    @ViewBuilder
    private var albumsListView:some View{
        GeometryReader{ proxy in
            VStack{
                ScrollView(.horizontal,showsIndicators: false){
                    HStack{
                        AlbumRow(assets: vm.fetchPhotosFirstAssets(mode: .all), text: PhotosFilter.all.rawValue) {
                            photosMode = .all
                            vm.album = nil
                            vm.fetchAlbumAssets(from: nil, condition: nil)
                            guard let asset = vm.fetchPhotosFirstAssets(mode:.all) else{ return self.backgroundImage = nil }
                            vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.backgroundImage = $0 }
                        }
                        ForEach(vm.albums,id: \.id) { album in
                            AlbumRow(assets: album.asset, text: album.title) {
                                photosMode = .other
                                vm.album = album
                                vm.fetchAlbumAssets(from: album.collection, condition: nil)
                                guard let asset = vm.fetchAlbumsFirstAssets(collection: album.collection) else{ return self.backgroundImage = nil }
                                vm.fetchImageFromAsset(asset: asset,targetSize: CGSize(width: width(), height: height())) { self.backgroundImage = $0 }
                            }
                        }
                    }.padding(.horizontal)
                }.show(show)
            }
            .onAppear{ mainOffsetY = proxy.frame(in: .global).maxY }
            .onChange(of: show) { value in
                withAnimation {
                    mainOffsetY = value ? proxy.frame(in: .global).maxY: lastminY
                }
            }
        }
        .frame(height: width()/3.5 + 20)
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


extension PhotosView{
    
    //Method--------------------------------------------------------------------------------------------------
    
    ///**생성자**
    ///- PhotosView 첫생성 시 호출
    ///- 초기 gird 아이템 수 초기화
    ///- 앨범리스트 배경이미지 업데이트
    private func initializer(){
        gridItemSize = CGSize(width: width()/numberOfColumns, height: width()/numberOfColumns)
        guard let asset = vm.fetchPhotosFirstAssets(mode:.all) else {return}
        let size = CGSize(width: width(), height: height())
        vm.fetchImageFromAsset(asset: asset, targetSize: size){ self.backgroundImage = $0 }
    }
    ///**항목리스트 업데이트**
    ///- photosMode의 변화에 따라 현재 항목 리스트를 업데이트함
    ///- 앨범리스트가 아닌 항목 타입에 따라 리스트를 변결하는 메서드
    ///
    ///**예시**
    ///- 사진 : 즐겨찾기, 스크린샷
    ///- 비디오 : 비디오, 스트리밍 비디오
    private func updateListEvent(value:PhotosFilter){
        switch value{
        case .all,.other: break
        case .bookmark:             vm.assetList = vm.assets.filter{ $0.isFavorite }
        case .video:                vm.assetList = vm.assets.filter{ $0.mediaType == .video }
        case .photoScreenshot:      vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoScreenshot }
        case .photoLive:            vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoLive }
        case .photoHDR:             vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoHDR }
        case .photoPanorama:        vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoPanorama }
        case .photoDepthEffect:     vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .photoDepthEffect }
        case .videoStreamed:        vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .videoStreamed }
        case .videoCinematic:       vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .videoCinematic }
        case .videoTimelapse:       vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .videoTimelapse }
        case .videoHighFrameRate:   vm.assetList = vm.assets.filter{ $0.mediaSubtypes == .videoHighFrameRate }
        }
    }
    ///**항목 터시 이벤트**
    ///- 항목 아이템을 터치 시 호출되는 메서드
    ///
    ///- 현재 아이템의 인덱스 값을 저장
    ///- 각 미디어 타입에 따라서 Asset을 업데이트
    private func tapItemEvent(index:Int,asset:PHAsset){
        vm.progress = true
        self.selectedIndex = index
        switch asset.mediaType{
        case .image: withAnimation(.spring(response: 0.25)) { self.selectedAsset = AssetItem(asset: asset) }
        case .video: playVideo(asset: asset){ self.selectedAsset = AssetItem(asset: asset, playerItem: AVPlayer(playerItem: $0)) }
        default: return
        }
    }
    ///**스크롤 업/다운 이벤트**
    ///- 스크롤 업/다운함에 따라 스크롤뷰의 minY값을 감지해 앨범 리스트뷰를 show/hide하는 이벤트
    ///
    ///- 임계값 15이상 움직일 경우 실행
    ///- 앨범리스트가 show/hide됨에 따라 lastminY이 달라짐
    private func scrollEvent(value:CGFloat){
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
    
    //View--------------------------------------------------------------------------------------------------
    ///**그리드 아이템 오버레이**
    ///- 아이템이 즐겨찾기 일 경우 하트 표시
    ///- 아이템이 비디오일 경우 재생시간 표시
    @ViewBuilder
    private func itemOverlay(asset:PHAsset)-> some View{
        HStack{
            Image(systemName: "heart.fill").show(asset.isFavorite)
            Text(asset.duration.timeFormatter()).show(asset.mediaType == .video)
        }
        .foregroundColor(.white)
        .shadow(color:.black.opacity(0.5),radius: 1)
        .padding(4)
    }
    ///**상단 컨트롤뷰**
    ///- 상단에서 전체적으로 이미지 리스트를 컨트롤 할 수 있는 뷰
    ///
    ///### 주요기능
    ///- 항목 카테고리 변경
    ///- 앨범 리스트 선택
    ///- 정렬 및 비율 조정
    ///- 제목, 항목 개수 포함등
    @ViewBuilder
    private var headerControllView:some View{
        VStack(spacing: 0){
            HStack{
                headerView
                Spacer()
                ratioView
                    .padding()
                    .show(!show)
                CustomButton(image: "ellipsis", buttonColor: .clear, imageColor: .white) {
                    withAnimation {
                        menu.toggle()
                    }
                }
                .padding()
                .show(show)
            }
            .background(LinearGradient(colors: [.black.opacity(0.3),.clear], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            optionCategoryView
                .show(show)
            albumsListView
        }
    }
    ///**비율조절버튼**
    ///-  뷰의 크기에 맞게 혹은 뷰를 완전히 채우도록 비율 조정
    @ViewBuilder
    private var ratioView:some View{
        let text1 = isFill ? "forward" : "backward"
        let text2 = !isFill ? "forward" : "backward"
        CustomButton(image: "arrow.down.\(text1).and.arrow.up.\(text2)", text: "비율", buttonColor: .gray, imageColor: .white) {
            withAnimation {
                isFill.toggle()
            }
        }
    }
    ///**제목**
    ///- 현재 항목 리스트 이름과 항목 개수를 반환
    @ViewBuilder
    private var headerView:some View{
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
    ///**항목 아이템 썸네일 뷰**
    ///
    ///- 각 항목의 사이즈는 핀치 인&아웃 제스쳐로 크기가 조절됨
    ///- 항목 터치 시 항목 상세 뷰 호출
    @ViewBuilder
    private func assetItemsRowView(asset:PHAsset,index:Int)-> some View{
        Group{
            if selectedAsset == nil{
                PhotosItemView(assets: .constant(asset))
                    .aspectRatio(contentMode: isFill ? .fill : .fit)
                    .frame(width: gridItemSize.width, height: gridItemSize.height)
                    .clipShape(Rectangle())
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .matchedGeometryEffect(id: asset.localIdentifier, in: namespace)
                    .overlay(alignment:.bottomTrailing){ itemOverlay(asset: asset) }
                    .onTapGesture{ tapItemEvent(index:index,asset:asset) }
            }
            else{
                Color.clear.frame(width: gridItemSize.width, height: gridItemSize.height)
            }
        }
        .transition(.move(edge: .bottom))
    }
    //ETC--------------------------------------------------------------------------------------------------
    
    ///**그리드 핀치 인&아웃 제스쳐**
    ///
    ///- 핀치 인&아웃을 함에 따라 그리드의 칸수를 변경하는 제스쳐
    ///- 최소 1칸 최대 5칸 까지 변화가능
    private var gridAdjustmenGesture:some Gesture{
        MagnificationGesture()
            .onChanged { value in
                withAnimation(.spring()){
                    let scaleDifference = value.magnitude / self.lastScale
                    
                    if scaleDifference > 1.2 {
                        if numberOfColumns > 1 { numberOfColumns -= 1 }
                        self.lastScale = value.magnitude
                    }
                    if scaleDifference < 0.8 {
                        if numberOfColumns < 5 { numberOfColumns += 1 }
                        self.lastScale = value.magnitude
                    }
                    gridItemSize = CGSize(width: width() / CGFloat(numberOfColumns), height: width() / CGFloat(numberOfColumns))
                }
            }
            .onEnded { _ in
                withAnimation(.spring()){
                    self.lastScale = 1.0
                }
            }
    }
}


