//
//  parser.swift
//  term
//
//  Created by Matthew Nibecker on 6/7/22.
//

import Foundation

func parse(_ data: Data, _ term: Terminal) {
    var it = data.makeIterator()
    while true {
        guard let c = it.next() else {
            return 
        }
        switch c {
        case 0x05...0x0F:
            escape(c, term)
        case 0x1B:
            guard parseEsc(&it, term) else {
                print("returned early")
                return 
            }
        default:
            if c < 0x20 {
                print("UNSUPPORTED CHAR!")
            } else {
                var s: Unicode.Scalar = Unicode.Scalar(c)
                if Unicode.UTF8.isASCII(c) {
                    s = Unicode.Scalar(c)
                } else {
                    var me = sequence(first:c,next:{_ in it.next()})
                    var decoder = UTF8()
                    Decode: while true {
                        switch decoder.decode(&me) {
                        case .scalarValue(let v):
                            s = v
                            break Decode
                        case .emptyInput:
                            print("empty input!")
                            break Decode
                        case .error:
                            print("decoding error!")
                            break Decode
                        }
                    }
                }
                term.write(s)
            }
        }
    }
}

func escape(_ c: UInt8, _ term: Terminal) {
    switch c {
    case 0x0D:
        term.buffer.x = 0
    case 0x0A:
        term.buffer.y += 1
        term.buffer.x = 0
    case 0x07:
        print("ding ding")
    case 0x08:
        print("backspace")
        term.buffer.x -= 1
    default:
        print("unhandled escape:", c) 
    }
}

func parseEsc(_ it: inout Data.Iterator, _ term: Terminal) -> Bool {
    guard let c = it.next() else { return false }
    switch c {
    case 0x5B:
        return parseCSI(&it, term)
    case 0x50:
        print("Device Control Sequence")
    case 0x5D:
        print("Unhandled OSC")
    default:
        print("escape command:", c)
    }
   if c == 0x91 {
        print("ugh")
   }
   return true
}

func parseCSI(_ it: inout Data.Iterator, _ term: Terminal) -> Bool {
    var final: UInt8 = 0
    var i: [UInt8] = []
    var param: [UInt8] = []
    var done = false
    while !done {
        guard let c = it.next() else { return false }
        switch c {
        case 0x30...0x3F:
            param.append(c)
        case 0x20...0x2F:
            i.append(c)
        case 0x40...0x7E:
            final = c
            done = true
        default:
            print("UNKOWN SEQUENCE!")
        }
    }
    var intermediate = String(bytes:i, encoding:.utf8)!
    var params = String(bytes:param, encoding:.utf8)?.split(separator: ";") ?? [] as [Substring]
    switch final {
    case 0x68:
        print("csi: set mode", params, intermediate)
    case 0x71: // q
        print("csi: set cursor style", params, intermediate)
    case 0x43: // C
        csiMoveCursor(params, term, false)
    case 0x44: // D
        csiMoveCursor(params, term, true)
    case 0x4A: // J
        // erase in display
        csiEraseInDisplay(params, term)
    case 0x4B: // K
        // erase in line
        csiEraseInLine(params, term)
        
    case 0x6D:
        sgr(params, intermediate)
    default:
        print("unknown CSI:", final, params)
    }
    return true
}

func sgr(_ params: [Substring], _ intermediate: String) {
    for p in params {
        switch p {
        case "00", "0", "":
           print("sgr: somekind of foregraound background set")
        case "01", "1":
            print("sgr: set text bold")
        case "32":
            print("sgr: set foreground green")
        case "36":
            print("sgr: foreground cyan")
        default:
            print("unhandled sgr", params, intermediate)
        }
    }
}

