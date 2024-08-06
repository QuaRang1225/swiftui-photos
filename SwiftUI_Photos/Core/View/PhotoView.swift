//
//  ImageListView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/6/24.
//

import SwiftUI

struct PhotoView: View {
    @StateObject var vm = PhotoViewModel()
    
    var body: some View {
        Text("테스트")
    }
}

#Preview {
    ImageListView()
}

struct PhotoLibraryView: View {
    let items = [GridItem(),GridItem(),GridItem()]
    let width = UIScreen.main.bounds.width
    @StateObject var vm = PhotoLibraryViewModel()

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
