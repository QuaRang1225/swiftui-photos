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
        .environmentObject(vm)
    }
}

#Preview {
    ContentView()
}
