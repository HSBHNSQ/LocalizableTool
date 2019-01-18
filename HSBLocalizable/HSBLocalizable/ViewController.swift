//
//  ViewController.swift
//  HSBLocalizable
//
//  Created by mac mini on 18/1/2019.
//  Copyright © 2019 小白兔. All rights reserved.
//

import Cocoa

class ViewController: NSViewController , LAWExcelParserDelegate{

    
    
    
    @IBOutlet weak var filePathLabel: NSTextField!
    @IBOutlet weak var countryNumberLabel: NSTextField!
    @IBOutlet weak var targetPathLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
           
        }
    }
  
    
    @IBAction func openFile(_ sender: Any) {
        
        let panel = NSOpenPanel()
//        panel.prompt = "选择翻译xlsx文件"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["csv","xls","xlsx"]
        panel.begin { (response) in
            if response == .OK {
                var string = panel.urls.first?.absoluteString
                string = string?.replacingOccurrences(of: "file://", with: "")
                self.filePathLabel.stringValue = string ?? ""
            }
        }
    }
    
    @IBAction func targetPathChoose(_ sender: Any) {
        let panel = NSOpenPanel()
//        panel.prompt = "选择存储位置"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.begin { (response) in
            if response == .OK {
                var string = panel.urls.first?.absoluteString
                string = string?.replacingOccurrences(of: "file://", with: "")
                self.targetPathLabel.stringValue = string ?? ""
            }
        }
    }
    
    @IBAction func startAction(_ sender: Any) {
        if self.filePathLabel.stringValue.count == 0 {
            print("请选择文件")
            return
        }
        if self.targetPathLabel.stringValue.count == 0 {
            print("请选择存储位置")
            return
        }
        if self.countryNumberLabel.stringValue.count == 0 {
            print("请输入翻译国家个数")
            return
        }
        LAWExcelTool.shareInstance().delegate = self
        LAWExcelTool.shareInstance()?.parserExcel(withPath: filePathLabel.stringValue)
    }
    
   
    //LAWExcelParserDelegate
    func parser(_ parser: LAWExcelTool!, success responseObj: Any!) {
        DispatchQueue.main.async {
            let result = responseObj as! [[String:String]]
            let number = Int(self.countryNumberLabel.stringValue) ?? 0
            print(result.count)
            print(result.count/number)
            //有十五个国家，m所以每行有15个值，第一行为汉字国家，第二行为各个国家的代码，往后每行均为一个词条的各个国家的翻译
            //第1步：把数组分为每15个元素为一组
            let count = result.count / number
            var A:[[[String:String]]] = []
            for x in 0..<count {
                var B:[[String:String]] = []
                for y in 0..<number {
                    let index = x * number + y
                    let value = result[index]
                    B.append(value)
                }
                A.append(B)
            }
            //第2步： 取出第二行 创建文件夹
            let folderNames = A[1]
            var folderPaths:[String] = []
            let manager = FileManager.default
            for dic in folderNames {
                let name = dic["value"] ?? ""
                let path = self.targetPathLabel.stringValue + name + ".lproj"
                folderPaths.append(path)
                if !manager.fileExists(atPath: path) {
                    do {
                        try manager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                    }catch {
                        print("创建文件夹失败")
                        print(error)
                    }
                }
            }
            // 第3步： 取出简体翻译和英语翻译
            var jiantiArray:[[String:String]] = []
            for index in 0..<A.count {
                let a = A[index]
                jiantiArray.append(a[0])
            }
            var enArray:[[String:String]] = []
            for index in 0..<A.count {
                let a = A[index]
                enArray.append(a[2])
            }
            //第4步： 创建string文件
            var stringFilePath:[String] = []
            for folder in folderPaths {
                let path = folder + "/Localizable.string"
                stringFilePath.append(path)
            }
            
            //第5步：翻译整理
            var fanyiString:[String] = []
            for _ in 0..<number{
                let s = ""
                fanyiString.append(s)
            }
            
            for index in 2..<A.count {
                let a = A[index]// 每个词条各个的国家翻译
                let jianti = jiantiArray[index]["value"] ?? ""
                let en = enArray[index]["value"] ?? ""
                for i in 0..<a.count {
                    let totalFanyi = fanyiString[i]
                    let fanyi = a[i]["value"] ?? ""
                    let newValue = "/// " + jianti + "\n" + "\"" + en + "\"" + " = " + "\"" + fanyi + "\";\n"
                    fanyiString[i] = totalFanyi + newValue
                }
            }
            // 保存
            for i in 0..<stringFilePath.count {
                let path = stringFilePath[i]
                let fanyi =  fanyiString[i]
                do {
                    try fanyi.write(toFile: path, atomically: true, encoding: .utf8)
                }catch {
                    print("保存失败")
                    print(error)
                }
                
            }
        }
       
        
    }
}

