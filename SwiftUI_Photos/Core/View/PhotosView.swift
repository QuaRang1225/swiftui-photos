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
    @State private var position = CGSize.zero
    @Namespace private var namespace
    @StateObject var vm = PhotoViewModel()
    
    @State private var size: CGSize = .zero
    
    var body: some View {
        
        ZStack{
            imageListView
            imageItemView
        }
        .progress(vm.progress)
        .userAllowAccessAlbum(vm.accessDenied)
        .onAppear{
            size = CGSize(width: width()/numberOfColumns, height: width()/numberOfColumns)
        }
    }
    var imageListView:some View{
        NavigationView {
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
                            .onTapGesture {
                                withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
                                    selectedAssets = asset
                                }
                            }
                            .environmentObject(vm)
                    }
                    
                }
            }
            .navigationBarTitle("갤러리")
        }
    }
    @ViewBuilder
    var imageItemView:some View{
        Color.black
            .ignoresSafeArea()
            .opacity(selectedAssets == nil ? 0 : min(1, max(0, 1 - abs(Double(position.height) / 800))))
        if let selectedAssets {
            PhotosItemView(assets: selectedAssets)
                .scaledToFit()
                .matchedGeometryEffect(id: selectedAssets.localIdentifier, in: namespace)
                .offset(position)
                .gesture(imageCloseGesture)
                .environmentObject(vm)
        }
    }
    var imageCloseGesture:some Gesture{
        DragGesture()
            .onChanged { value in
                self.position = value.translation
            }
            .onEnded { value in
                withAnimation(.spring()) {
                    if 50 < self.position.height {
                        self.selectedAssets = nil
                    }
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    self.position = .zero
                }
            }
    }
}

#Preview {
    PhotosView()
}
