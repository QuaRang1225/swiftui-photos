//
//  PhotosFilter.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/9/24.
//

import Foundation

enum PhotosFilter:String,CaseIterable{
    case all = "전체 항목"
    case bookmark = "즐겨찾는 항목"
    case video = "비디오"
    case photoScreenshot = "스크린샷"
    case photoLive = "Live Photo"
    case photoHDR = "HDS"
    case photoPanorama = "파노라마"
    case photoDepthEffect = "깊이 효과 사진"
    case videoStreamed = "스트리밍 비디오"
    case videoCinematic = "시네마틱 비디오"
    case videoTimelapse = "타임랩스 비디오"
    case videoHighFrameRate = "고프레임 비디오"
    case other
    
    var type:MediaTypeFilter{
        switch self{
        case .all,.bookmark,.photoHDR,.photoLive,.photoPanorama,.photoScreenshot,.photoDepthEffect:
            return .photo
        case .video,.videoStreamed,.videoCinematic,.videoTimelapse,.videoHighFrameRate,.other:
            return .video
        }
    }
    var image: String {
        switch self {
        case .all:
            return "tray.full"
        case .bookmark:
            return "star.fill"
        case .video:
            return "video.fill"
        case .photoScreenshot:
            return "camera.fill"
        case .photoLive:
            return "livephoto"
        case .photoHDR:
            return "highlighter"
        case .photoPanorama:
            return "panorama"
        case .photoDepthEffect:
            return "camera.filters"
        case .videoStreamed:
            return "play.fill"
        case .videoCinematic:
            return "film"
        case .videoTimelapse:
            return "clock.fill"
        case .videoHighFrameRate:
            return "speedometer"
        case .other:
            return "questionmark"
        }
    }
}
