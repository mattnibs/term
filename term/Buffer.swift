//
//  Buffer.swift
//  term
//
//  Created by Matthew Nibecker on 6/8/22.
//

import Cocoa
import Foundation

class Buffer: NSObject {
    var lines: [Line] = []
    var x: Int = 0
    var y: Int = 0
    
    func write(_ c: Unicode.Scalar) {
        if lines.count <= y {
            let n = lines.count
            for _ in n...(y+1) {
                lines.append(Line())
            }
        }
        x += 1
        lines[y].write(x, c)
    }
    
    func eraseLineFromCursor() {
        lines[y].clearFrom(x)
    }
    
    func eraseFromCursor() {
        lines[y].clearFrom(x)
        for line in lines[y+1..<lines.count] {
            line.cells = line.cells[..<0]
        }
    }
    
    func moveCursor(_ n: Int) {
        x += n
    }
    
    func print() {
        for l in lines {
            Swift.print(l.string())
        }
    }
    
    // func setSize(_ rows: Int, _ cols: Int)
}

class Line: NSObject {
    var cells: ArraySlice<Unicode.Scalar> = []
    
    func clearFrom(_ x: Int) {
        cells = cells[0..<x]
    }
    
    func write(_ x: Int, _ c: Unicode.Scalar) {
        if cells.count <= x {
            let add = Array(repeating: Unicode.Scalar(32 as UInt8), count: x - cells.count + 1)
            cells += add
            //self.cells.append(contentsOf: add)
        }
        cells[x] = c
    }
    
    func string() -> String {
        var s = ""
        for c in cells {
            s.append(Character(c))
        }
        return s
    }
}

struct Cell {
    var char: UInt32 = 0
}

struct FontGlyphRun {
  var font: NSFont
  var glyphs: [CGGlyph]
  var positions: [CGPoint]
}
