//
//  ImageOptionViewModifier.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import Foundation
import SwiftUI

struct ImageOptionViewModifier:ViewModifier{
    let condition:Bool
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.caption)
            .padding(2.5)
            .padding(.horizontal,2.5)
            .background {
                Color.gray.opacity(0.5)
                    .cornerRadius(2)
            }
            .show(condition)
    }
}

#Preview {
    Text("Hello, world!")
        .modifier(ImageOptionViewModifier(condition: false))
}
