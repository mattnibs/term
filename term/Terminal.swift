//
//  Terminal.swift
//  term
//
//  Created by Matthew Nibecker on 6/7/22.
//

import SwiftUI
import Cocoa
import Foundation

struct TerminalWrap: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = Terminal()
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
    }
}

public class Terminal: NSView, TTYDelegate {
    
    var font: NSFont
    var cellSize: CGSize
    var buffer = Buffer()
    var tty: TTY
    
    public override var acceptsFirstResponder: Bool { true }
    
    public init() {
        //        font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        font = NSFont(name: "SF Mono", size: 14)!
        tty = TTY()
        cellSize = Terminal.setCellSize(font)
        super.init(frame: .zero)
        self.display()
        tty.run(self)
    }
    
    static func setCellSize(_ font: NSFont) -> CGSize {
        // get height
        let lineAscent = CTFontGetAscent(font)
        let lineDescent = CTFontGetDescent(font)
        let lineLeading = CTFontGetLeading(font)
        let cellHeight = ceil(lineAscent + lineDescent + lineLeading)
        // get width
        let capitalM = [UniChar(0x004D)]
        var glyph = [CGGlyph(0)]
        var advancement = CGSize.zero
        CTFontGetGlyphsForCharacters(font, capitalM, &glyph, 1)
        CTFontGetAdvancesForGlyphs(font, .horizontal, glyph, &advancement, 1)
        let cellWidth = advancement.width
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func dataRead(_ data: Data) {
        parse(data, self)
        buffer.print()
    }
    
    func write(_ c: Unicode.Scalar) {
        buffer.write(c)
        self.needsDisplay = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func keyDown(with event: NSEvent) {
        // print("\(event.keyCode) \(event.characters)")
        guard let s = event.characters else {
            print("no characters")
            return
        }
        let chars = ([UInt8] (s.utf8))[...]
        if chars.count == 1 && chars[0] == 127 {
            tty.send([ 0x7F ])
            return
        }
        print("string", s)
        tty.send(chars)
        // interpretKeyEvents([event])
    }
    
    open func insertText(_ string: Any, replacementRange: NSRange) {
        print("string", string)
        if let str = string as? NSString {
            tty.send(([UInt8] ((str as String).utf8))[...])
        }
    }
    
    override open func viewWillDraw() {
        let layer = self.layer
        layer?.contentsFormat = .RGBA8Uint
    }
    
    override public func setFrameSize(_ newSize: NSSize) {
        var ws = winsize()
        ws.ws_row = UInt16(newSize.height / cellSize.height)
        ws.ws_col = UInt16(newSize.width / cellSize.width)
        print(ws)
        tty.setWinSize(&ws)
        super.setFrameSize(newSize)
    }
    
    override public func draw(_ dirtyUnionRect: NSRect) {
        print("draw", frame.origin)
        guard let context = NSGraphicsContext.current?.cgContext else {
            print("couldn't get gccontext!")
            return
        }
        context.setFillColor(CGColor.white)
        context.fill(frame)
        let rows = Int(frame.height / cellSize.height)
        var start = 0
        if buffer.lines.count > rows {
            start = buffer.lines.count - rows
        }
        var y: Double = frame.maxY - cellSize.height
        for line in buffer.lines[start..<buffer.lines.count] {
            drawLine(context, line, y)
            y -= cellSize.height
        }
    }
    
    func drawLine(_ context: CGContext, _ line: Line, _ y: Double) {
        context.saveGState()
        context.setFillColor(CGColor.black)
        let attrStr = NSAttributedString(
            string: line.string(),
            attributes: [.font: font]
        )
        let ctline = CTLineCreateWithAttributedString(attrStr)
        var col = 0
        for run in CTLineGetGlyphRuns(ctline) as? [CTRun] ?? [] {
            let count = CTRunGetGlyphCount(run)
            let runAttributes = CTRunGetAttributes(run) as? [NSAttributedString.Key: Any] ?? [:]
            let runFont = runAttributes[.font] as! NSFont
            let glyphs = [CGGlyph](unsafeUninitializedCapacity: count) { (bufferPointer, c) in
                CTRunGetGlyphs(run, CFRange(), bufferPointer.baseAddress!)
                c = count
            }
            var pos = glyphs.enumerated().map { (i: Int, glyph: CGGlyph) -> CGPoint in
//                CGPoint(x: lineOrigin.x + (cellDimension.width * CGFloat(col + i)), y: lineOrigin.y + ceil(lineLeading + lineDescent))
                CGPoint(x: cellSize.width * CGFloat((col + i)), y: y)
            }
            CTFontDrawGlyphs(runFont, glyphs, &pos, pos.count, context)
            col += count
        }
        context.restoreGState()
        // CTLineDraw(ctline, context)
//        let chars = line.cells.withUnsafeBufferPointer{p -> [UInt16] in
//            let count = p.reduce(0) { acc, elem in acc + elem.utf16.count }
//            return [UInt16](unsafeUninitializedCapacity: count) { buffer, i in
//                for char in p {
//                    for c in char.utf16 {
//                        buffer[i] = c
//                        i += 1
//                    }
//                }
//            }
//        }
//        let chars = [UInt16](unsafeUninitializedCapacity: str.utf16.count) { buffer, i in
//            for c in str.utf16 {
//                buffer[i] = c
//                i += 1
//            }
//        }
//        var glyphs = [CGGlyph](repeating: CGGlyph(), count: line.cells.count)
//        let success = CTFontGetGlyphsForCharacters(font, chars, &glyphs, line.cells.count)
//        if !success {
//            print("did not get glyphs, nah")
//            return
//        }
//        print("count", line.cells.count)
//        let pos = [CGPoint](unsafeUninitializedCapacity: line.cells.count) {buffer, _ in
//            for i in 0..<line.cells.count {
//                let x = Double(i)*font.boundingRectForFont.width
//                buffer[i] = CGPoint(x: x,y: y)
//            }
//        }
//        CTFontDrawGlyphs(font, glyphs, pos, line.cells.count, context)
    }
}
