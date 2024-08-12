//
//  PhotosItemView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/7/24.
//

import SwiftUI
import Photos

struct PhotosItemView: View {
    @Binding var assets:PHAsset
    @EnvironmentObject var vm: PhotoViewModel
    @State var image:UIImage?
    var body: some View {
        ZStack{
            if let image{
                Image(uiImage: image)
                    .resizable()
            }else{
                Color.gray.opacity(0.1)
            }
        }
        .onAppear{
            vm.fetchImageFromAsset(asset: assets,targetSize: CGSize(width: width(), height: height())) { image = $0 }
        }
        .onChange(of: assets) { assets in
            vm.fetchImageFromAsset(asset: assets,targetSize: CGSize(width: width(), height: height())) { image = $0 }
        }
    }
}


#Preview {
    PhotosItemView(assets: .constant(PHAsset()))
}
