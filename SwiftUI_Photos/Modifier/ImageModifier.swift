//
//  ImageModifier.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/7/24.
//

import Foundation
import SwiftUI

struct ImageModifier: ViewModifier {
    let width:CGFloat
    let height:CGFloat
    func body(content: Content) -> some View {
        content
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
    }
}
