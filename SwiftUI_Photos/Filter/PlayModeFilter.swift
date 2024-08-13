//
//  PlayMode.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import Foundation

///**비디오의 플레이 모드를 설정하는 필터**
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
