//
//  Home.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct Home: View {
    @State var selection: Panel? = nil
    @State var viewModel = HomeViewModel()
    var body: some View {
        NavigationSplitView {
            Sidebar(selection: $selection, homeViewModel: viewModel) 
        } detail: {
            DetailColumn(selection: $selection, viewModel: viewModel)
        }
        .onAppear {
            selection = viewModel.firstSelection()
        }
    }
}

#Preview {
    Home()
}
