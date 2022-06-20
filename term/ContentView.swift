//
//  ContentView.swift
//  term
//
//  Created by Matthew Nibecker on 6/7/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TerminalWrap()
            .padding()
            .frame(minWidth: 400, minHeight: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
