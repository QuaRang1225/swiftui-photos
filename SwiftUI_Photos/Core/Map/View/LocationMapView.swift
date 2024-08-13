//
//  LocationMapView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/9/24.
//

import SwiftUI
import Photos
import MapKit

///**항목이 위치한 지도 뷰**
///
///- 항목의 지도를 터치하면 나오는 뷰
///- 항목이 생성된 위치를 시각적으로 확인할 수 있는 뷰
struct LocationMapView: View {
    let buttonMode:Bool
    let annotions:[City]
    @State private var region = MKCoordinateRegion()
    let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    @Environment(\.dismiss) var dismiss
    @StateObject var vm = PhotoViewModel()
    
    var body: some View {
        ZStack{
            Map(coordinateRegion: $region, annotationItems: annotions) {
                MapAnnotation(coordinate: $0.coordinate.coordinate) {
                    mapAnnotationsView
                }
            }
            .ignoresSafeArea()
            mapOverlayView
        }
        .onAppear{
            guard let coordinate = annotions.first?.coordinate.coordinate else{return}
            region = MKCoordinateRegion(center: coordinate, span: span)
        }
    }
    ///**지도 컨트롤 뷰**
    ///
    ///- 해당 지도를 닫는 버튼
    ///- 항목이 위치한 주소를 제목으로 표시
    ///-
    @ViewBuilder
    var mapOverlayView:some View{
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
                        dismiss()
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
                backButton
            }
        }
    }
    ///**맵 어노테이션뷰**
    ///
    ///- 해당 위치에서 항목 생성 위치를 표시하는 뷰
    ///- 항목의 이미지를 포함하고 있음
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
    ///**원 위치 버튼**
    ///
    ///- 맵을 이동 중에 항목의 위치로 다시 이동하는 버튼
    @ViewBuilder
    var backButton:some View{
        Button {
            guard let coordinate = annotions.first?.coordinate.coordinate else { return }
            withAnimation {
                region = MKCoordinateRegion(center: coordinate, span: span)
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

#Preview {
    LocationMapView(buttonMode: true, annotions: [City(asset: PHAsset(), country: "asdasd", city: "asd", district: "asda")])
        .environmentObject(PhotoViewModel())
}
