//
//  ViewController.swift
//  RemoveMarkForMac
//
//  Created by mac mini on 1/2/2019.
//  Copyright © 2019 小白兔. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {

    @IBOutlet weak var filePathLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//(BOOL startRuning,float progress, BOOL stopRuning)
        
        
        // Do any additional setup after loading the view.
    }

    @IBAction func chooseFilew(_ sender: Any) {
        let panel = NSOpenPanel()
        //        panel.prompt = "选择翻译xlsx文件"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
//        panel.allowedFileTypes = ["csv","xls","xlsx"]
        panel.begin { (response) in
            if response == .OK {
                var string = panel.urls.first?.absoluteString
                string = string?.replacingOccurrences(of: "file://", with: "")
                self.filePathLabel.stringValue = string ?? ""
            }
        }
    }
    
    @IBAction func startButton(_ sender: Any) {
        HSBFFmpegUtil.shareInstance()?.videoCrop(NSRect(x: 0, y: 0, width: 100, height: 100), biteRate: 15768 * 1000, inputPath: self.filePathLabel.stringValue, outputPath: "Users/macmini/Desktop/VideoPicture/000.mov", progressBlock: { (startRuning, progress, stopRuning) in
            print(progress)
        })
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

