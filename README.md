# CommandTask

## 概要

[NSTaskを非同期で実行する](http://qiita.com/_ha1f/items/49a3643a9da3fd999626)

## Usage

#### simple usage

```swift
let task = CommandTask(cmd: "/usr/bin/curl", arguments: ["https://qiita.com"])
            .addObserver { string in
                print("observe", string)}
            .addCompletionHandler {
                print("complete")}
            .launch()
```

This uses method chaining, so this is same as following source code.

```swift
let task = CommandTask(cmd: "/usr/bin/curl", arguments: ["https://qiita.com"])
task.addObserver { string in print("observe", string) }
task.addCompletionHandler { print("complete") }
task.launch()
```

#### interactive writing

```swift
task.writeln("some string")
```

#### terminating

```swift
task.terminate()
```

## How to use

1. copy CommandTask.swift to your project
1. write like usage


