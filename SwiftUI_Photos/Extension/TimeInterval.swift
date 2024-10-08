//
//  TimeInterval.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import Foundation

extension TimeInterval {
    ///**시간 차이를 문자열로 반환**
    ///- ex) 5 -> 0:05
    ///- ex) 67 -> 1:07
    func timeFormatter() -> String {

        let minute = Int(self) / 60
        let second = Int(self) % 60
        
        let minuteFormatter = String(format: "%d", minute)
        let secondFormatter = String(format: "%02d", second)

        if minute > 0 {
            return "\(minuteFormatter):\(secondFormatter)"
        } else {
            return "0:\(secondFormatter)"
        }
    }
}
