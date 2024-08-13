//
//  MediaTypeFilter.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/10/24.
//

import Foundation

///**항목의 카테고리를 설정하는 필터**
enum MediaTypeFilter:String,CaseIterable{
    case photo = "사진"
    case video = "비디오"
    
    var code:Int{
        switch self{
        case .photo:1
        case .video:2
        }
    }
}
