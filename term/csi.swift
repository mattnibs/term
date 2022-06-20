//
//  csi.swift
//  term
//
//  Created by Matthew Nibecker on 6/19/22.
//

import Foundation

func csiEraseInDisplay(_ params: [Substring], _ term: Terminal) {
    var n:Substring = "0"
    if params.count > 0 {
        n = params[0]
    }
    switch n {
    case "0","":
        term.buffer.eraseFromCursor()
    default:
        print("unhandled csi erase in display", n)
    }
}

func csiEraseInLine(_ params: [Substring], _ term: Terminal) {
    var n:Substring = "0"
    if params.count > 0 {
        n = params[0]
    }
    switch n {
    case "0","":
        term.buffer.eraseLineFromCursor()
    default:
        print("unhandled csi erase in line", n)
    }
}

func csiMoveCursor(_ params: [Substring], _ term: Terminal, _ reverse: Bool) {
    print("moveCursor", params, reverse)
    var n = 1
    if params.count > 0 {
        n = Int(params[0]) ?? 1
    }
    if reverse {
        n = n * -1
    }
    term.buffer.moveCursor(n)
}
