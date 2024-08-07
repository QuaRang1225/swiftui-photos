//
//  ImageListView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import SwiftUI

struct PhotosView: View {
    let items = [GridItem(),GridItem(),GridItem()]
    @StateObject var vm = PhotoViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: items,spacing: 3){
                    ForEach(vm.assets.indices, id: \.self) { index in
                        let assets = vm.assets[index]
                        PhotosItemView(assets: assets)
                            .environmentObject(vm)
                    }
                }
            }
            .userAllowAccessAlbum(vm.accessDenied)
            .navigationBarTitle("갤러리")
        }
    }
}

#Preview {
    PhotosView()
}
