//
//  SeleteAssetView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import SwiftUI
import AVFoundation
import Photos

struct SelectAssetView: View {
    ///지도 상태변수
    ///- true : show
    ///- fasle : hide
    @State var isMap = false
    ///항목 상태변수
    ///- true : show
    ///- fasle : hide
    @State var info = false
    ///앨범 리스트를 show/hide할 변수
    ///- true : show
    ///- fasle : hide
    @Binding var show:Bool
    
    
    ///현재 오프셋
    ///- 항목의 위치를 나타내는 상태변수
    @State var currentOffset = CGSize.zero
    ///마지막 오프셋
    ///- 현재 오프셋을 계산하기 위한 상태변수
    @State var endOffset = CGSize.zero
    ///현재 스케일
    ///- 항목의 크기를 나타내는 상태변수
    @State var currentScale:CGFloat = 1
    ///현재 오프셋
    ///- 현재 스케일을 계산하기 위한 상태변수
    @State var endScale:CGFloat = 1
    ///항목의 이동을 감지하는 상태변수
    @GestureState var changed = false
    ///항목의 주소를 저장하는 상태변수
    @State var address:(country:String?, city:String?,district:String?)?
    
    ///matchedGeometryEffect를 공유하기 위한 변수
    let namespace: Namespace.ID
    ///현재 항목
    @Binding var selectedAsset: AssetItem?
    ///현재 항목의 인덱스
    @Binding var selectedIndex: Int
    ///현재 항목의 모드
    @Binding var photosMode:PhotosFilter
    @EnvironmentObject var vm:PhotoViewModel
    
    ///썸네일 그룹 배열
    var generateArray:[Int]{
        switch vm.assetList.count {
        case 1...9: return Array(0...(vm.assetList.count - 1))
        default:break
        }
        var indexRange = Array(selectedIndex-4...selectedIndex+4)
        indexRange = indexRange.map { $0 < 0 ? abs($0 - (indexRange.last ?? 0)) : $0 }
        indexRange = indexRange.map { $0 > vm.assetList.count-1 ?  (indexRange.first ?? 0) - ($0 - vm.assetList.count) : $0 }
        return Array(Set(indexRange).sorted())
    }
    
    var body: some View {
        ZStack{
            if let selectedAsset{
                Color.reversal.ignoresSafeArea()
                VStack{
                    infoTextView(asset: selectedAsset.asset)
                        .show(!info)
                    assetView(asset: selectedAsset)
                    thumnailGroupView(asset: selectedAsset.asset)
                    infoControllView.padding(30)
                        .show(!info)
                    infoView(asset:selectedAsset.asset)
                        .show(info)
                }
            }
        }
        .fullScreenCover(isPresented: $isMap){ locationMapView }
        .simultaneousGesture(dragGesture)
        .environmentObject(vm)
    }
}

#Preview {
    SelectAssetView(show: .constant(true), namespace: Namespace().wrappedValue, selectedAsset: .constant(nil), selectedIndex: .constant(0), photosMode: .constant(.bookmark))
        .environmentObject(PhotoViewModel())
}

extension SelectAssetView{
    
    //Method--------------------------------------------------------------------------------------------------
    ///**항목이 나타났을 때 이벤트**
    ///
    ///- 현재 항목이 나타났을 때 즐겨찾기가 되있는지 확인하는 이벤트
    func assetAppearEvent(asset:PHAsset){
        vm.isFavorite = asset.isFavorite
        vm.progress = false
    }
    ///**항목을 움직임을 제한하는 이벤트**
    ///
    ///항목을 드래그해 화면 바깥으로 나가지 않기 위한 이벤트
    ///각 항목의 프레임 값을 받아 그 안에서의 움직임의 차이를 구해 구현
    func frameRestrictionEvent(proxy:CGRect,change:Bool){
        withAnimation(.easeIn(duration: 0.1)){
            if proxy.minX > 0{ currentOffset.width = currentOffset.width - proxy.minX }
            if proxy.minY > 0{ currentOffset.height = currentOffset.height - proxy.minY }
            if proxy.maxX < width(){ currentOffset.width = proxy.minX - currentOffset.width }
            if proxy.maxY < width(){ currentOffset.height = proxy.minY - currentOffset.height }
            if !change{ endOffset = currentOffset }
        }
    }
    ///**항목을 더블탭 했을때 이벤트**
    ///
    ///- 항목을 더블터치하면 현 상황에 따라 해당 항목을 두배 키우거나 원래로 되돌림
    func dobleTapEvent(){
        withAnimation {
            if currentScale == 1{
                currentScale = 2
                endScale = 2
            }else{
                currentScale = 1
                endScale = 1
                currentOffset = .zero
                endOffset = .zero
            }
        }
    }
    ///**페이지 넘길때 이벤트**
    ///
    ///- 항목을 좌우로 넘길때 생기는 이벤트 처리
    ///- 미디어 타입에 따라 항목을 업데이트 하고 다음 항목이 나올때까지 progress
    func turnPageEvent(){
        Task{
            if let address = await vm.assetList[selectedIndex].location?.fetchAddress(){ self.address = address }
        }
        guard vm.assetList[selectedIndex].mediaType == .video else{ return selectedAsset = AssetItem(asset: vm.assetList[selectedIndex]) }
        vm.progress = true
        playVideo(asset: vm.assetList[selectedIndex]){
            self.selectedAsset = AssetItem(asset: vm.assetList[selectedIndex], playerItem: AVPlayer(playerItem: $0))
        }
    }
    //View--------------------------------------------------------------------------------------------------
    ///**지도 - 네비게이션**
    ///
    ///- 뷰에 나타내기 위한 뷰가 아닌 이동할 뷰
    @ViewBuilder
    var locationMapView:some View{
        if let address,let ci = address.city,let co = address.country,let di = address.district,let selectedAsset{
            let city = City(asset: selectedAsset.asset, country: co, city: ci, district: di)
            LocationMapView(buttonMode: false, annotions: [city])
        }
    }
    ///**항목 뷰**
    ///
    ///- AssetItem에 plyerItem이 존재할 경우 비디오 표시
    ///- 아닐 경우 이미지 표시
    @ViewBuilder
    func assetView(asset:AssetItem)-> some View{
        if let video = asset.playerItem{
            VideoPlayerView(item: video)
                .onAppear{ assetAppearEvent(asset: asset.asset) }
        }else{
            GeometryReader{ geo in
                let proxy = geo.frame(in: .named("G"))
                PhotosItemView(assets: .constant(asset.asset))
                    .scaledToFit()
                    .frame(maxWidth: .infinity,maxHeight: .infinity)
                    .matchedGeometryEffect(id: asset.asset.localIdentifier, in: namespace)
                    .onChange(of: changed) { frameRestrictionEvent(proxy: proxy, change: $0) }
            }
            .scaleEffect(currentScale)
            .offset(currentOffset)
            .simultaneousGesture(pinch)
            .onTapGesture(count: 2, perform: dobleTapEvent)
            .coordinateSpace(name: "G")
            .onAppear{ assetAppearEvent(asset: asset.asset) }
        }
    }
    ///**썸네일 그룹**
    ///
    ///- 현재 항목 기준으로 전/후 4개씩 이미지를 보여줌
    ///- 이미지를 좌우로 드래그해서 넘길 수 있음
    @ViewBuilder
    func thumnailGroupView(asset:PHAsset)->some View{
        HStack{
            ForEach(generateArray,id: \.self){ index in
                PhotosItemView(assets: .constant(vm.assetList[index]))
                    .scaledToFill()
                    .animation(.spring,value: asset == vm.assetList[index])
                    .frame(width: asset == vm.assetList[index] ? 40:20,height: asset == vm.assetList[index] ? 60:40)
                    .clipped()
                    .cornerRadius(3)
            }
        }
    }
    ///**날짜 표시 뷰**
    ///
    ///항목 상세정보에서 확인 가능한 원복 혹은 수정된 날짜 표시
    @ViewBuilder
    func date(title:String,date:String)->some View{
        HStack{
            Text(title).bold()
            Spacer()
            Text(date)
        }.padding(.horizontal,5)
    }
    ///
    ///**지도 - 표시**
    ///
    ///- 만약 항목이 생성된 주소가 존재할 경우 항목하단에 지도 배치
    ///- 지도하단에는 생성된 주소 텍스트 표시
    @ViewBuilder
    func mapView(asset:PHAsset) -> some View{
        if let address{
            Button {
                isMap = true
            } label: {
                VStack(spacing: 0){
                    let annotations = [
                        City(asset: asset, country:address.country ?? "미확인 구역", city: address.city ?? "", district: address.district ?? "")
                    ]
                    LocationMapView(buttonMode: true, annotions:annotations)
                        .frame(height: 150)
                        .allowsHitTesting(false)
                    HStack{
                        if let city = address.city,let district = address.district{
                            Text("\(city) - \(district)").foregroundColor(.blue)
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
    }
    ///**항목 상세정보**
    ///
    ///- 항목의 정보들을 표시하는 패널
    ///- 항목 타입: 사진 or 비디오
    ///- 항목 이름
    ///- 항목의 크기 및 위치
    ///- 항목의 날짜
    ///- 항목의 생성 위치
    @ViewBuilder
    func infoView(asset:PHAsset) -> some View{
        let mediaTypeText = MediaTypeFilter.allCases.first(where: {$0.code == asset.mediaType.rawValue})?.rawValue ?? "알수 없는 형식"
        VStack(alignment:.leading,spacing:10){
            Text(mediaTypeText)
                .font(.title2)
                .bold()
                .padding(.bottom,5)
            Text("\(asset.localIdentifier)")
                .opacity(0.5)
            HStack{
                Text("Burst")
                    .modifier(ImageOptionViewModifier(condition: asset.representsBurst))
                Text("Edited")
                    .modifier(ImageOptionViewModifier(condition: asset.hasAdjustments))
            }
            VStack{
                HStack{
                    Text("\(SourceTypeFilter.allCases.first(where: {$0.code == asset.sourceType.rawValue})?.rawValue ?? "")")
                    Spacer()
                    Text("SIZE : ")
                    Text("\(asset.pixelWidth.removeCommas()) x \(asset.pixelHeight.removeCommas())")
                        .opacity(0.5)
                }
                .padding(5)
                .background(Color.gray.opacity(0.5))
                date(title:"원본",date: asset.creationDate.formattedDate())
                date(title:"수정",date: asset.modificationDate.formattedDate())
            }
            .padding(.bottom,5)
            .background(Color.reversal)
            .cornerRadius(5)
            infoControllView.show(info)
        }
        .padding()
        .background{
            VStack(spacing:0){
                Divider()
                Color.gray
                    .opacity(0.1)
                    .ignoresSafeArea()
            }
            .shadow(radius: 10)
        }
        .gesture(infoDragGesture)
        .task{ self.address = await asset.location?.fetchAddress() }
        .onChange(of: selectedAsset?.asset ?? PHAsset()){ asset in
            Task{ self.address = await asset.location?.fetchAddress() }
        }
    }
    ///**항목의 제목**
    ///
    ///- 항목이 생성된 날짜와 요일을 제목으로 표시
    @ViewBuilder
    func infoTextView(asset:PHAsset)->some View{
        HStack{
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
                withAnimation(.easeIn(duration: 0.1)) {
                    self.selectedAsset = nil
                }
                
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.primary)
            }
        }
        .padding()
    }
    ///**항목 관련 기능**
    ///
    ///- 공유 기능
    ///- 즐겨찾기 추가 기능
    ///- 상세정보
    ///- 삭제
    @ViewBuilder
    var infoControllView:some View{
        HStack{
            CustomButton(image: "square.and.arrow.up", buttonColor: .gray.opacity(0.3), imageColor: .blue) {
                guard let selectedAsset else { return }
                fetchImage(from: selectedAsset.asset) { shareMedia(image: $0, videoURL: nil) }
            }
            Spacer()
            HStack{
                let favoriteImage = vm.isFavorite ? "heart.fill" : "heart"
                CustomButton(image:favoriteImage , buttonColor: .clear, imageColor: .blue) {
                    guard let selectedAsset else { return }
                    vm.assetFavorite(asset: selectedAsset.asset,isFavorite:vm.isFavorite){ asset,favorite  in
                        vm.isFavorite = favorite
                        guard let index = vm.assetList.firstIndex(where: {$0 == selectedAsset.asset}),let asset else{ return }
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
                .padding(.horizontal,15)
                let infoImage = !info ? "info.circle" : "info.circle.fill"
                CustomButton(image: infoImage, buttonColor: .clear, imageColor: .blue) {
                    withAnimation { info.toggle() }
                }
                .padding(.horizontal,15)
            }
            .background(Color.gray.opacity(0.3))
            .clipShape(Capsule())
            
            Spacer()
            CustomButton(image: "trash", buttonColor: .gray.opacity(0.3), imageColor: .black) {
                guard let selectedAsset else { return }
                vm.deleteAssetLibrary(asset: selectedAsset.asset){ asset in
                    withAnimation(.easeIn(duration: 0.1)) {
                        vm.assetList = vm.assetList.filter{ $0 != asset }
                        vm.assets = vm.assetList
                        self.selectedAsset = nil
                        self.show = false
                        vm.fetchAlbums()
                    }
                }
            }
        }
        .matchedGeometryEffect(id: "info", in: namespace)
    }
    //ETC--------------------------------------------------------------------------------------------------
    ///**핀치 인&아웃 제스쳐**
    ///
    ///- 이미지를 줌 인&아웃해서 크기를 조절할 수 있는 제스쳐
    var pinch:some Gesture{
        MagnificationGesture()
            .updating($changed){ _,changed,_ in
                changed = true
            }
            .onChanged { gesture in
                currentScale = min(max(gesture + endScale - 1, 1), 3)
            }
            .onEnded { gesture in
                withAnimation(.easeIn(duration: 0.1)){
                    endScale = min(max(endScale + gesture - 1, 1), 3)
                    guard endScale < 1  else { return }
                    currentScale = 1
                    endScale = 1
                    currentOffset = .zero
                    endOffset = .zero
                }
            }
        
    }
    ///**항목 상세정보 컨트롤 제스쳐**
    ///
    ///- 항목의 상세정보를 닫을 수 있는 제스쳐
    var infoDragGesture: some Gesture{
        DragGesture()
            .onEnded{ gesture in
                if gesture.translation.height > 0{
                    withAnimation {
                        self.info = false
                    }
                }
            }
    }
    ///**항목 드래그 제스쳐**
    ///
    ///- 항목을 직접 움직일 수 있는 제스쳐
    ///- 항목이 화면 맞춤 비율일때는 드래그를 하지 못하게 제한
    ///- 항목을 상하좌우로 움직일 때 각기 다른 이벤트 구현
    var dragGesture:some Gesture{
        DragGesture()
            .updating($changed){ _,changed,_ in
                if currentScale != 1{ changed = true }
            }
            .onChanged{ gesture in
                if currentScale != 1{ currentOffset = endOffset + gesture.translation }
            }
            .onEnded { gesture in
                guard currentScale == 1 else { return }
                if gesture.translation.width < -50{
                    guard selectedIndex < vm.assetList.count-1 else {return}
                    self.selectedIndex += 1
                    turnPageEvent()
                }
                if gesture.translation.width > 50{
                    guard selectedIndex > 0 else {return}
                    self.selectedIndex -= 1
                    turnPageEvent()
                }
                if gesture.translation.height < -50{
                    withAnimation {
                        self.info = true
                    }
                }
                if gesture.translation.height > 50{
                    withAnimation(.easeIn(duration: 0.25)) {
                        if info{
                            self.info = false
                        }else{
                            self.selectedAsset = nil
                        }
                    }
                }
            }
    }
}
