//
//  CircleButton.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import SwiftUI

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
