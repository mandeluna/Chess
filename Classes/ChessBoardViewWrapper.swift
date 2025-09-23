//
//  ChessBoardViewWrapper.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-23.
//

import Foundation
import SwiftUI

struct ChessBoardViewWrapper: UIViewRepresentable {
    typealias UIViewType = ChessBoardView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIViewType {
        let view = UIViewType()
        context.coordinator.view = view
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    class Coordinator: NSObject {
        var parent: ChessBoardViewWrapper
        weak var view: UIViewType?

        init(_ parent: ChessBoardViewWrapper) {
            self.parent = parent
            super.init()
        }
    }
}
