//
//  AlbumRow.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import SwiftUI
import Photos

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
