//
//  CLLocation.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/10/24.
//

import Foundation
import CoreLocation

extension CLLocation{
    func fetchAddress() async -> (country:String?, city:String?,district:String?){
        let geocoder = CLGeocoder()
        
        let country = try? await geocoder.reverseGeocodeLocation(self).first?.country
        let city = try? await geocoder.reverseGeocodeLocation(self).first?.locality
        let district = try? await geocoder.reverseGeocodeLocation(self).first?.subLocality
        
        let adress = (country, city, district)
        
        return adress
    }
}

