//
//  PlayMode.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import Foundation

enum PlayModeFilter:CaseIterable{
    case slow
    case normal
    case quick
    
    var rate:Float{
        switch self{
        case .slow: 0.5
        case .normal: 1.0
        case .quick: 2.0
        }
    }
    var image:String{
        switch self{
        case .slow: "tortoise.fill"
        case .normal: "figure.run"
        case .quick: "hare.fill"
        }
    }
}
