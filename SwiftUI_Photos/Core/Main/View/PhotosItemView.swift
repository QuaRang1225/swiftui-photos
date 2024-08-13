//
//  PhotosItemView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/7/24.
//

import SwiftUI
import Photos

///**항목 이미지뷰**
///- 선택한 PHAsset타입을 UIImage로 바꿔주는 컴포넌트
struct PhotosItemView: View {
    @State var image:UIImage?
    @Binding var assets:PHAsset
    @EnvironmentObject var vm: PhotoViewModel
    
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
