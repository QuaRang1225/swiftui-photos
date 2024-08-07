//
//  PhotosItemView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/7/24.
//

import SwiftUI
import Photos

struct PhotosItemView: View {
    let assets:PHAsset
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
        .modifier(ImageModifier(width:width()/3,height:width()/3))
        .onAppear{
            vm.fetchImageFromAsset(asset: assets,targetSize: CGSize(width: width(), height: width())) { image = $0 }
        }
    }
}


#Preview {
    PhotosItemView(assets: PHAsset())
}
