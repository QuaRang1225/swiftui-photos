//
//  CircleButton.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import SwiftUI

///**커스텀 버튼**
///
///- 파라미터를 받아서 버튼을 생성하는 컴포넌트
///- 이미지, 라벨, 버튼 및 이미지 색상, 이벤트 
struct CustomButton: View {
    let image:String
    var text:String?
    let buttonColor:Color
    let imageColor:Color
    let action: () -> ()
    var body: some View {
        Button(action:action){
            VStack{
                Image(systemName:image)
                    .foregroundColor(imageColor)
                    .font(.title3)
                    .padding(10)
                    .background(Circle().foregroundColor(buttonColor))
                if let text{
                    Text(text)
                        .shadow(radius: 1)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    CustomButton(image: "heart", text: nil, buttonColor: .gray, imageColor: .blue){
        
    }
}
