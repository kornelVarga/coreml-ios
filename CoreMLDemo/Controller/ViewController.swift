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
    @IBOutlet var btnPickImage: UIButton!

    var predictionList = [Prediction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        btnPickImage.layer.cornerRadius = 10
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            imgGuess.contentMode = .scaleAspectFit
            imgGuess.image = pickedImage
            
            recogniseImage(image: pickedImage)
            
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func recogniseImage(image: UIImage) {
        predictionList.removeAll()
        let model = scene_classification()
        
        do {
            if let pb = image.pixelBuffer(width: 224, height: 224) {
                let predictions = try model.prediction(image: pb)
                
                for prediction in predictions.output {
                    
                    predictionList.append(Prediction(label: prediction.key, probability: prediction.value))
                    updateUI()
                }
            }
        } catch {
            print("Error while doing predictions: \(error)")
        }
    }
    
    func updateUI() {
        var outputText = ""
        
        for prediction in predictionList {
            var str = NSString(format: "\(prediction.label) -> %.2f" as NSString, prediction.probability * 100) as String
            str += "%"
            outputText += "\(str)\n"
        }
        
        txtOutput.text = outputText
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
}

extension UIImage {
    
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey
                        :kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32ARGB,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer
            else {
                return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        guard let context =
            CGContext(data: pixelData,
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
