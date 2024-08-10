//
//  Date.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/10/24.
//

import Foundation

extension Date?{
    func formattedDate() -> String {
        guard let self else {
            return "알 수 없음"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일 EEEE a h:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        return dateFormatter.string(from: self)
    }
}
