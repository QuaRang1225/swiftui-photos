//
//  SeleteAssetView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import SwiftUI
import AVFoundation
import Photos

struct SeleteAssetView: View {
    @State var isMap = false
    @State var info = false
    @State var videoOffset:CGSize = .zero
    
    @State var endOffset = CGSize.zero
    @State var currentOffset = CGSize.zero
    @State var mainCurrentScale:CGFloat = 1
    @State var endScale:CGFloat = 1
    @GestureState var changed = false
    @State var address:(country:String?, city:String?,district:String?)?
    
    @Binding var selectedAsset: AssetItem?
    @Binding var selectedIndex: Int
    @Binding var photosMode:PhotosFilter
    @Binding var show:Bool
    @EnvironmentObject var vm:PhotoViewModel
    let namespace: Namespace.ID
    
    var generateArray:[Int]{
        switch vm.assetList.count {
        case 1...9:
            return Array(0...(vm.assetList.count - 1))
        default:
            break
        }
        var indexRange = Array(selectedIndex-4...selectedIndex+4)
        indexRange = indexRange.map { element in
            if element < 0 {
                return abs(element - (indexRange.last ?? 0))
            } else {
                return element
            }
        }
        indexRange = indexRange.map { element in
            if element > vm.assetList.count-1 {
                return  (indexRange.first ?? 0) - (element - vm.assetList.count)
            } else {
                return element
            }
        }
        print(Array(Set(indexRange).sorted()))
        return Array(Set(indexRange).sorted())
    }
    
    var body: some View {
        ZStack{
            if let selectedAsset{
            Color.reversal.ignoresSafeArea()
            VStack{
                if !info{
                    infoTextView
                }
               
                    if let video = selectedAsset.playerItem{
                        VideoPlayerView(item: video, offset: $videoOffset)
                            .onAppear{
                                vm.isFavorite = selectedAsset.asset.isFavorite
                                vm.progress = false
                            }
                        if !info{
                            infoControllView
                                .padding(30)
                                .matchedGeometryEffect(id: "info", in: namespace)
                        }
                    }else{
                        GeometryReader{ geo in
                            let g = geo.frame(in: .named("G"))
                            PhotosItemView(assets: .constant(selectedAsset.asset))
                                .scaledToFit()
                                .frame(maxWidth: .infinity,maxHeight: .infinity)
                                .matchedGeometryEffect(id: selectedAsset.asset.localIdentifier, in: namespace)
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
                        .simultaneousGesture(pinch)
                        .onTapGesture(count: 2) {
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
                            vm.isFavorite = selectedAsset.asset.isFavorite
                            vm.progress = false
                        }
                        if !info{
                            infoControllView
                                .padding(30)
                                .matchedGeometryEffect(id: "info", in: namespace)
                        }
                    }
                    HStack{
                        ForEach(generateArray,id: \.self){ index in
                            PhotosItemView(assets: .constant(vm.assetList[index]))
                                .scaledToFill()
                                .animation(.spring,value: selectedAsset.asset == vm.assetList[index])
                                .frame(width: selectedAsset.asset == vm.assetList[index] ? 40:20,height: selectedAsset.asset == vm.assetList[index] ? 60:40)
                                .clipped()
                                .cornerRadius(3)
                        }
                    }
                    
                    
                    if info{
                        infoView(asset:selectedAsset.asset)
                    }
                    
                }
            }
        }
        .fullScreenCover(isPresented: $isMap){
            if let address,let ci = address.city,let co = address.country,let di = address.district,let selectedAsset{
                let city = City(asset: selectedAsset.asset, country: co, city: ci, district: di)
                LocationMapView(buttonMode: false, annotions: [city], dismiss: $isMap)
            }
        }
        .simultaneousGesture(drag)
        .environmentObject(vm)
        
    }
    var infoTextView:some View{
        HStack{
            if let selectedAsset{
                VStack(alignment: .leading){
                    let date = selectedAsset.asset.creationDate.formattedTitleDate()
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
        }
        .padding()
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
            if let address{
                Button {
                    isMap = true
                } label: {
                    VStack(spacing: 0){
                        LocationMapView(buttonMode: true, annotions: [City(asset: asset, country:address.country ?? "미확인 구역", city: address.city ?? "", district: address.district ?? "")], dismiss: .constant(false))
                            .frame(height: 150)
                            .allowsHitTesting(false)
                        HStack{
                            if let c = address.city,let d = address.district{
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
                infoControllView
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
        .task{
            self.address = await asset.location?.fetchAddress()
        }
        .onChange(of: selectedAsset?.asset ?? PHAsset()){ asset in
            Task{
                self.address = await asset.location?.fetchAddress()
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
                }
            }
            .onEnded { gesture in
                if mainCurrentScale == 1{
                    if gesture.translation.width < -50{
                        guard selectedIndex < vm.assetList.count-1 else {return}
                        self.selectedIndex += 1
                        Task{
                            if let address = await vm.assetList[selectedIndex].location?.fetchAddress(){
                                self.address = address
                            }
                        }
                        if vm.assetList[selectedIndex].mediaType == .video{
                            vm.progress = true
                            playVideo(asset: vm.assetList[selectedIndex]){ playerItem in
                                self.selectedAsset = AssetItem(asset: vm.assetList[selectedIndex], playerItem: AVPlayer(playerItem: playerItem))
                            }
                        }else{
                            selectedAsset = AssetItem(asset: vm.assetList[selectedIndex])
                        }
                    }
                    if gesture.translation.width > 50{
                        guard selectedIndex > 0 else {return}
                        self.selectedIndex -= 1
                        Task{
                            if let address = await vm.assetList[selectedIndex].location?.fetchAddress(){
                                self.address = address
                            }
                        }
                        if vm.assetList[selectedIndex].mediaType == .video{
                            vm.progress = true
                            playVideo(asset: vm.assetList[selectedIndex]){ playerItem in
                                self.selectedAsset = AssetItem(asset: vm.assetList[selectedIndex], playerItem: AVPlayer(playerItem: playerItem))
                            }
                        }else{
                            selectedAsset = AssetItem(asset: vm.assetList[selectedIndex])
                        }
                    }
                    if gesture.translation.height < -50{
                        withAnimation {
                            self.info = true
                        }
                    }
                    if gesture.translation.height > 50{
                        withAnimation(.easeIn(duration: 0.1)) {
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
    var infoControllView:some View{
        HStack{
            Button {
                if let selectedAsset {
                    fetchImage(from: selectedAsset.asset) { img in
                        shareMedia(image: img, videoURL: nil)
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
                    if let selectedAsset {
                        DispatchQueue.global().async {
                            vm.assetavorite(asset: selectedAsset.asset,isFavorite:vm.isFavorite){ asset,favorite  in
                                vm.isFavorite = favorite
                                if let index = vm.assetList.firstIndex(where: {$0 == selectedAsset.asset}),let asset{
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
                    Image(systemName:vm.isFavorite ? "heart.fill" : "heart")
                }
                .padding(.trailing,30)
                Button {
                    withAnimation {
                        info.toggle()
                    }
                } label: {
                    Image(systemName:!info ? "info.circle" : "info.circle.fill")
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
                if let selectedAsset {
                    vm.deleteAssetLibrary(asset: selectedAsset.asset) { asset in
                        DispatchQueue.main.async {
                            withAnimation(.easeIn(duration: 0.1)) {
                                vm.assetList = vm.assetList.filter{$0 != asset}
                                vm.assets = vm.assetList
                                self.selectedAsset = nil
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
}

#Preview {
    SeleteAssetView(selectedAsset: .constant(nil), selectedIndex: .constant(0), photosMode: .constant(.bookmark), show: .constant(true), namespace: Namespace().wrappedValue)
        .environmentObject(PhotoViewModel())
}
