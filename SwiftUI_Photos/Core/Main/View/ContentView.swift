//
//  ContentView.swift
//  SwiftUI_Photos
//
//  Created by 유영웅 on 8/8/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = PhotoViewModel()
    var body: some View {
        NavigationView{
            PhotosView()
                .environmentObject(vm)
        }
    }
}

#Preview {
    ContentView()
}
