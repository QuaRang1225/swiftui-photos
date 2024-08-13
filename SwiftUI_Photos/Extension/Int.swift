//
//  Int.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/10/24.
//

import Foundation

extension Int{
    ///**1,000이상의 숫자 콤마(,)제거**
    func removeCommas() -> String {
        return String(self).replacingOccurrences(of: ",", with: "")
    }
}
