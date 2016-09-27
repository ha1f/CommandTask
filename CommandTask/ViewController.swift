//
//  ViewController.swift
//  CommandTask
//
//  Created by はるふ on 2016/09/07.
//  Copyright © 2016年 はるふ. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var task: CommandTask!

    override func viewDidLoad() {
        super.viewDidLoad()
        task = CommandTask(cmd: "/usr/bin/curl", arguments: ["https://qiita.com"])
            .addObserver { string in
                print("observe", string)}
            .addCompletionHandler {
                print("complete")
            }
            .launch()
    }

}

