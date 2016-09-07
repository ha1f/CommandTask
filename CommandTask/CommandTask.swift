//
//  CommandTask.swift
//  CommandTask
//
//  Created by はるふ on 2016/09/07.
//  Copyright © 2016年 はるふ. All rights reserved.
//

import Foundation

class CommandTask {
    
    private static let ENCODING = NSUTF8StringEncoding
    
    private let task = NSTask()
    private let outputPipe = NSPipe()
    private let inputPipe = NSPipe()
    
    private var outputObserver: (String -> ())?
    private var completionHandler: (() -> ())?
    
    init(cmd: String, arguments: [String] = []) {
        task.launchPath = cmd
        task.arguments = arguments
        task.standardInput = inputPipe
        task.standardOutput = outputPipe
    }
    
    func setCurrentDirectoryPath(path: String) -> Self {
        task.currentDirectoryPath = path
        return self
    }
    
    func addObserver(observer: String -> ()) -> Self {
        self.outputObserver = observer
        return self
    }
    
    func addCompletionHandler(handler: () -> ()) -> Self {
        self.completionHandler = handler
        return self
    }
    
    func removeObserver() {
        outputObserver = nil
    }
    
    func launch() -> Self {
        guard !task.running else {
            return self
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(NSFileHandleDataAvailableNotification, object: outputPipe.fileHandleForReading, queue: nil, usingBlock:  { [weak self] (notification: NSNotification!) in
            guard let `self` = self else {
                return
            }
            
            let dataHandler: (NSData) -> () = { data in
                if let outStr = NSString(data: data, encoding: CommandTask.ENCODING) {
                    let s = outStr as String
                    if s != "" {
                        self.outputObserver?(s)
                    }
                }
            }
            dataHandler(self.outputPipe.fileHandleForReading.availableData)
            
            if self.task.running {
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
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSFileHandleDataAvailableNotification, object: outputPipe.fileHandleForReading)
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
    
    func writeData(data: NSData) {
        inputPipe.fileHandleForWriting.writeData(data)
    }
    
    func write(string: String) {
        if let data = string.dataUsingEncoding(CommandTask.ENCODING) {
            writeData(data)
        }
    }
    
    func writeln(string: String) {
        write(string + "\n")
    }
    
}