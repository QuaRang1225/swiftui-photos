//
//  BlurBackGround.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import SwiftUI

///**Blur 배경화면**
///
///- 이미지와 높이를 입력받아 스크롤 업/다운 시 크기가 변하는 Sticky헤더 뷰
public struct BlurBackGround<Content:View>: View {
    
    let height:CGFloat
    let content:()->Content
    
    init(height: CGFloat,@ViewBuilder content: @escaping ()->Content) {
        self.height = height
        self.content = content
    }
    
    public var body: some View {
        GeometryReader{ geo in
            let minY = geo.frame(in: .global).minY
            content()
                .overlay{
                    Color.black.opacity(0.5)
                    Color.clear
                        .background(Material.thin)
                        .overlay(alignment:.bottom){
                            LinearGradient(colors: [.clear,.reversal], startPoint: .top, endPoint: .bottom)
                                .frame(height: 30)
                        }
                }
                .offset(x:minY > 0 ? -minY/2 : 0,y:minY > 0 ? -minY : 0)
                .frame(width: width() + (minY > 0 ? minY : 0),height: height + 20 + (minY > 0 ? minY: 0))
                .scaledToFill()
        }
        .padding(.bottom,(height - 10))
    }
}
#Preview {
    BlurBackGround(height: 2.5){
        
    }
}
    
