//
//  View.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import Foundation
import SwiftUI

extension View{
    func width()->CGFloat{
        UIScreen.main.bounds.width
    }
    func userAllowAccessAlbum(_ accessDenied:Bool) -> some View{
        ZStack{
            if !accessDenied{
                self
            }else{
                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    VStack(spacing:0){
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                        Text("앨범 접근에 허용해 주세요.")
                            .bold()
                        Text("사진 또는 동영상을 사용하기 위해 라이브러리에 접근하도록 허용해야 합니다.")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}
