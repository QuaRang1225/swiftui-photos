//
//  Int.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/10/24.
//

import Foundation

extension Int{
    func removeCommas() -> String {
        return String(self).replacingOccurrences(of: ",", with: "")
    }
}
