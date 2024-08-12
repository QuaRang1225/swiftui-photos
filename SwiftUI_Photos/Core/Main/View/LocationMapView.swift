//
//  LocationMapView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/9/24.
//

import SwiftUI
import Photos
import MapKit

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

struct LocationMapView: View {
    let buttonMode:Bool
    let annotions:[City]
    @State private var region = MKCoordinateRegion()
    let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    @Binding var dismiss:Bool
    @StateObject var vm = PhotoViewModel()
    
    var body: some View {
        ZStack(alignment: .top){
            Map(coordinateRegion: $region, annotationItems: annotions) {
                MapAnnotation(coordinate: $0.coordinate.coordinate) {
                    mapAnnotationsView
                }
            }
            .ignoresSafeArea()
            if let anno = annotions.first,!buttonMode{
                VStack{
                    HStack{
                        VStack(alignment: .leading){
                            Text(anno.country)
                                .font(.largeTitle)
                            HStack{
                                Text(anno.country)
                                    .font(.title3)
                                Text(anno.district)
                            }
                        }
                        .bold()
                        Spacer()
                        Button {
                            dismiss = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background{
                        LinearGradient(colors: [.black.opacity(0.5),.black.opacity(0.3),.clear], startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea()
                    }
                    Spacer()
                    Button {
                        if let coordinate = annotions.first?.coordinate.coordinate{
                            withAnimation {
                                region = MKCoordinateRegion(center: coordinate, span: span)
                            }
                        }
                    } label: {
                        Text("원 위치로 돌아가기")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(10)
                            .padding(.horizontal)
                            .background(Capsule().foregroundColor(.white))
                    }
                }
            }
        }
        .onAppear{
            if let coordinate = annotions.first?.coordinate.coordinate{
                region = MKCoordinateRegion(center: coordinate, span: span)
            }
        }
    }
    @ViewBuilder
    var mapAnnotationsView:some View{
        if let asset = annotions.first?.asset{
            VStack(spacing: 0){
                PhotosItemView(assets:.constant(asset))
                    .scaledToFill()
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .frame(width: 40,height: 40)
                    .padding(2)
                    .background(Circle())
                Image(systemName: "triangleshape.fill")
                    .rotationEffect(.degrees(180))
                    .offset(y:-7.5)
            }
            .foregroundColor(.gray)
            .offset(y:-27.5)
            .environmentObject(vm)
        }
    }
}

#Preview {
    LocationMapView(buttonMode: true, annotions: [City(asset: PHAsset(), country: "asdasd", city: "asd", district: "asda")], dismiss: .constant(false))
        .environmentObject(PhotoViewModel())
}
