//
//  City.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/13/24.
//

import Foundation
import Photos

struct City: Identifiable {
    let id = UUID()
    let asset: PHAsset
    let country: String
    let city: String
    let district: String
    let coordinate: CLLocation
    
    init(asset: PHAsset, country: String, city: String, district: String) {
        self.asset = asset
        self.country = country
        self.city = city
        self.district = district
        self.coordinate = asset.location ?? CLLocation()
    }
}
