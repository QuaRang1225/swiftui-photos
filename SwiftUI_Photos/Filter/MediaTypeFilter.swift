//
//  MediaTypeFilter.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/10/24.
//

import Foundation

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
