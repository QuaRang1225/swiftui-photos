//
//  ContentView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import SwiftUI

struct ContentView: View {
    @State var offsetX = CGFloat.zero
    @State var offset = CGSize.zero
    @StateObject var vm = PhotoViewModel()
    var body: some View {
        NavigationView{
            PhotosView()
                
        }
//        .offset(offset)
//        .onChange(of: offsetX){ value in
//            print(value)
//            if value > 70{
//                withAnimation {
//                    offset.height = 200
//                }
//            }
//            else if value < 300{
//                withAnimation {
//                    offset.height = .zero
//                }
//            }
//        }
        .environmentObject(vm)
    }
}

#Preview {
    ContentView()
}
