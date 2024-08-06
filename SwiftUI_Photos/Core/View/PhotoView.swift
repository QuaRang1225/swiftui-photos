//
//  ImageListView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import SwiftUI

struct PhotoView: View {
    let items = [GridItem(),GridItem(),GridItem()]
    let width = UIScreen.main.bounds.width
    @StateObject var vm = PhotoViewModel()
    
    var body: some View {
        NavigationView {
            List(vm.images, id: \.self) { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width/3, height: width/3)
                    .clipped()
            }
            .userAllowAccessAlbum(vm.accessDenied)
            .navigationBarTitle("Photo Library")
        }
    }
}

#Preview {
    PhotoView()
}
