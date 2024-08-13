//
//  AlbumRow.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import SwiftUI
import Photos

///**앨범 리스트 테이블 아이템**
///
///- 앨범 리스트를 선택할 수 있는 아이템의 Row뷰
///- asset,타이틀,컬렉션, 이벤트 호출가능
struct AlbumRow: View {
    let assets:PHAsset?
    let text:String
    var collcation:PHAssetCollection?
    let action:()->()
    var body: some View {
        Button(action:action){
            VStack{
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
                Text(text)
                    .modifier(AlbumListRowModifier())
            }
        }
    }
}

#Preview {
    AlbumRow(assets: PHAsset(), text: ""){
        
    }
}
