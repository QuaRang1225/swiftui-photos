//
//  CLLocation.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/10/24.
//

import Foundation
import CoreLocation

extension CLLocation{
    ///**좌표를 주소로 반환**
    ///
    ///- ex) <+0.00000000,+0.00000000> +/- 0.00m (speed 0.00 mps / course 0.00) @ "1970-01-01 00:00:00 +0000"
    ///- ex)  -> (미국,샌프란시스코,금융지구)
    func fetchAddress() async -> (country:String?, city:String?,district:String?){
        let geocoder = CLGeocoder()
        
        let country = try? await geocoder.reverseGeocodeLocation(self).first?.country
        let city = try? await geocoder.reverseGeocodeLocation(self).first?.locality
        let district = try? await geocoder.reverseGeocodeLocation(self).first?.subLocality
        
        let adress = (country, city, district)
        
        return adress
    }
}

