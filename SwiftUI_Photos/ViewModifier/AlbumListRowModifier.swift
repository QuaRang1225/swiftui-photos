//
//  AlbumListRowModifier.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import Foundation
import SwiftUI

///**앨범 리스트에 사용되는 뷰 수정자**
struct AlbumListRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .bold()
            .foregroundColor(.white)
            .lineLimit(1)
            .frame(width: 100)
    }
}

#Preview {
    Text("Hello, world!")
        .modifier(AlbumListRowModifier())
}
