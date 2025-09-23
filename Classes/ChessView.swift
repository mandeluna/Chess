//
//  ChessView.swift
//  Shaman
//
//  Created by Steve Wart on 2025-09-22.
//

import SwiftUI

struct ChessView: View {
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let availableHeight = geometry.size.height
                let size = min(availableWidth, availableHeight)
                ChessBoardViewWrapper()
                    .frame(width: size, height: size)
            }
            .padding(2.0)
        }
        .border(Color.gray, width: 1.0)
        .aspectRatio(1.0, contentMode: .fit)
        .ignoresSafeArea()
    }
}

#Preview {
    ChessView()
}
