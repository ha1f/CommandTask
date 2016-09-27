//
//  CommandTask.swift
//  CommandTask
//
//  Created by はるふ on 2016/09/07.
//  Copyright © 2016年 はるふ. All rights reserved.
//

import Foundation

class CommandTask {
    
    private static let ENCODING = String.Encoding.utf8
    
    private let task = Process()
    private let outputPipe = Pipe()
    private let inputPipe = Pipe()
    
    private var outputObserver: ((String) -> ())?
    private var completionHandler: (() -> ())?
    
    init(cmd: String, arguments: [String] = []) {
        task.launchPath = cmd
        task.arguments = arguments
        task.standardInput = inputPipe
        task.standardOutput = outputPipe
    }
    
    func setCurrentDirectoryPath(_ path: String) -> Self {
        task.currentDirectoryPath = path
        return self
    }
    
    func addObserver(_ observer: @escaping (String) -> ()) -> Self {
        self.outputObserver = observer
        return self
    }
    
    func addCompletionHandler(_ handler: @escaping () -> ()) -> Self {
        self.completionHandler = handler
        return self
    }
    
    func removeObserver() {
        outputObserver = nil
    }
    
    func launch() -> Self {
        guard !task.isRunning else {
            return self
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil, using:  { [weak self] (notification: Notification!) in
            guard let `self` = self else {
                return
            }
            
            let dataHandler: (Data) -> () = { data in
                if let outStr = NSString(data: data, encoding: CommandTask.ENCODING.rawValue) {
                    let s = outStr as String
                    if s != "" {
                        self.outputObserver?(s)
                    }
                }
            }
            dataHandler(self.outputPipe.fileHandleForReading.availableData)
            
            if self.task.isRunning {
                self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            } else {
                // タスクがすでに終了していたら、最後までデータを読む
                let data = self.outputPipe.fileHandleForReading.readDataToEndOfFile()
                dataHandler(data)
                self.completionHandler?()
            }
            })
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        task.terminationHandler = { [weak self] task in
            self?.terminate()
            // ここでcompletionHandler呼んでも、あとからNSFileHandleDataAvailableNotificationがくるので不自然
        }
        
        task.launch()
        
        return self
    }
    
    func terminate() {
        task.terminate()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading)
    }
    
    func waitUntilExit() -> Int32 {
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    func resume() -> Bool {
        return task.resume()
    }
    
    func suspend() -> Bool {
        return task.suspend()
    }
    
    func interrupt() {
        task.interrupt()
    }
    
    func writeData(_ data: Data) {
        inputPipe.fileHandleForWriting.write(data)
    }
    
    func write(_ string: String) {
        if let data = string.data(using: CommandTask.ENCODING) {
            writeData(data)
        }
    }
    
    func writeln(_ string: String) {
        write(string + "\n")
    }
    
}
