//
//  Sidebar.swift
//  HackNasa
//
//  Created by Angel Hernández Gámez on 04/10/25.
//

import SwiftUI

struct Sidebar: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showNewFile = false
    
    var body: some View {
        List(viewModel.files, id: \.id,
             selection: $viewModel.fileSelected) { file in
            NavigationLink(value: file.id) {
                Label(file.name, systemImage: "text.document")
            }
        }
             .toolbar {
                 ToolbarItem(placement: .primaryAction) {
                     Button("Agregar csv", systemImage: "plus") {
                         showNewFile = true
                     }
                 }
             }
             .sheet(isPresented: $showNewFile) {
                 
             }
             .onChange(of: viewModel.fileSelected) {
                 guard viewModel.fileSelected != nil else { return }
                 Task {
                     await viewModel.selectCSV()
                 }
             }
             .refreshable {
                 await viewModel.fetchFiles()
             }
             .navigationTitle("Archivos")
             .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    @Previewable @State var viewModel = HomeViewModel()
    
    NavigationSplitView {
        Sidebar(viewModel: viewModel)
    } content: {
        
    } detail: {
        
    }
    
}

