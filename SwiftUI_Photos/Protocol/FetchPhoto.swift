//
//  FetchAssets.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/7/24.
//

import Foundation
import Photos
import UIKit

protocol FetchPhoto{
    func fetchAssets()
    func fetchImageFromAsset(asset: PHAsset,targetSize:CGSize,completion: @escaping (UIImage?)->())
    func loadAssets()
}
