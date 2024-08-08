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
    func height()->CGFloat{
        UIScreen.main.bounds.height
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
    func progress(_ isLoading:Bool) -> some View{
        ZStack{
            self
            if isLoading{
                Color.black.opacity(0.5).ignoresSafeArea()
                VStack{
                    ProgressView()
                    Text("이미지를 불러오는 중입니다.")
                        .font(.caption)
                }
            }
        }
    }
    func itemCloseGesture(position: Binding<CGSize>,closeAction:@escaping()->()) -> some View{
        self
            .gesture(
                DragGesture()
                .onChanged { value in
                    position.wrappedValue = CGSize(width: 0, height: value.translation.height)
                }
                .onEnded { value in
                    if 50 < position.wrappedValue.height {
                        withAnimation(.spring(duration: 0.1)){
                            closeAction()
                            position.wrappedValue = .zero
                        }
                    }else{
                        withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
                            position.wrappedValue = .zero
                        }
                    }
                }
            )
        
    }
}
