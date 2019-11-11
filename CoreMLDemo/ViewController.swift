//
//  ViewController.swift
//  CoreMLDemo
//
//  Created by Kornel Varga on 2019. 10. 21..
//  Copyright © 2019. Kornel Varga. All rights reserved.
//

import UIKit
import CoreML
import Vision
import VideoToolbox

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet var txtOutput: UITextView!
    @IBOutlet var imgGuess: UIImageView!
    @IBOutlet var lblGuess: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            //lblGuess.text = "Thinking"
            imgGuess.contentMode = .scaleAspectFit
            imgGuess.image = pickedImage
            
            let model = scene_classification()
            
            do {
                if let pb = pickedImage.pixelBuffer(width: 224, height: 224) {
                    let prediction = try model.prediction(image: pb)
                    
                    var outText: String = ""
                    for out in prediction.output {
                        var str = NSString(format: "\(out.key) -> %.2f" as NSString, out.value * 100) as String
                        str += "%"
                        outText += "\(str)\n"
                    }
                    
                    txtOutput.text = outText
                
                }
            } catch {
                print("Error while doing predictions: \(error)")
            }
        
            picker.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
            
        }
    }
    
    func resize(image: UIImage, newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension UIImage {
  public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    var maybePixelBuffer: CVPixelBuffer?
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     width,
                                     height,
                                     kCVPixelFormatType_32ARGB,
                                     attrs as CFDictionary,
                                     &maybePixelBuffer)

    guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
      return nil
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

    guard let context = CGContext(data: pixelData,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    else {
      return nil
    }

    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)

    UIGraphicsPushContext(context)
    self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
    UIGraphicsPopContext()
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
  }
}
