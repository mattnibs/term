//
//  tty.swift
//  term
//
//  Created by Matthew Nibecker on 6/7/22.
//

import Foundation
import Darwin

protocol TTYDelegate: AnyObject {
    func dataRead(_ data: Data)
}

class TTY: NSObject {
    unowned var delegate: TTYDelegate?
    var task: Process?   
    var slaveFile: FileHandle?
    var masterFile: FileHandle?

    override init() {
        self.task = Process()
        var masterFD: Int32 = 0
        masterFD = posix_openpt(O_RDWR)
        grantpt(masterFD)
        unlockpt(masterFD)
        // self.masterFile.
        self.masterFile = FileHandle.init(fileDescriptor: masterFD)
        let slavePath = String.init(cString: ptsname(masterFD))
        self.slaveFile = FileHandle.init(forUpdatingAtPath: slavePath)
        self.task!.executableURL = URL(fileURLWithPath: "/usr/bin/login")
        self.task!.arguments = ["-fpl", "nibs"]
        self.task!.environment = ["COLORTERM":"truecolor","TERM":"xterm-256color"]
        self.task!.standardOutput = slaveFile
        self.task!.standardInput = slaveFile
        self.task!.standardError = slaveFile
    }
    
    func send(_ data: ArraySlice<UInt8>) {
        print("sending", data)
        data.withUnsafeBytes { p in
            let b = DispatchData(bytes: p)
            DispatchIO.write(toFileDescriptor: masterFile!.fileDescriptor, data: b, runningHandlerOn: DispatchQueue.global(qos: .userInitiated), handler:  { dd, errno in
                if errno != 0 {
                    print ("Error writing data to the child, errno=\(errno)")
                }
            })
        }
    }

    func run(_ delegate: TTYDelegate) {
        self.delegate = delegate
        do {
            try self.task!.run()
        } catch {
            print("could not start process")
        }
        masterFile!.readabilityHandler = { (h) -> Void in
            let data = h.availableData
            DispatchQueue.main.async { self.delegate!.dataRead(data) }
        }
        let ws = getWinSize()
        print("ws", ws)
    }
    
    func getWinSize() -> winsize {
        var w = winsize()
        let errno = ioctl(masterFile!.fileDescriptor, TIOCGWINSZ, &w)
        if errno != 0 {
            print("winsize.errno!!", errno)
        }
        return w
    }
    
    func setWinSize(_ w: inout winsize) {
        let errno = ioctl(masterFile!.fileDescriptor, TIOCSWINSZ, &w)
        if errno != 0 {
            print("winsize.errno!!", errno)
        }
    }

}
