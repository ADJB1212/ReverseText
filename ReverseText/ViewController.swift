//
//  ViewController.swift
//  Final Project
//
//  Created by Andrew Jaffe-Berkowitz on 4/3/20.
//  Copyright © 2020 Andrew Jaffe-Berkowitz. All rights reserved.
//

import CoreImage
import CoreMedia
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase
import Foundation
import UIKit

class MainVideoViewController: UIViewController {

    var wordsArray: [String] = []

    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var drawingView: DrawingView!
    @IBOutlet weak var CloseTextButtonOutlet: UIButton!
    @IBOutlet weak var convertButtonOutlet: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var MainView: UIView!
    @IBOutlet weak var printButtonOutlet: UIButton!

    // MARK: - ML Kit Vision Property
    lazy var vision = Vision.vision()
    lazy var textRecognizer = vision.onDeviceTextRecognizer()
    var isInference = false
    var outputText = ""
    var storeUrl = ""
    // MARK - Performance Measurement Property

    var ref: DatabaseReference!

    // MARK: - AV Property
    var videoCapture: VideoCapture!

    override func viewDidLoad() {
        super.viewDidLoad()

        videoPreview.alpha = 0

        videoPreview.layer.cornerRadius = 10
        UIView.animate(withDuration: 1.2) {

            self.videoPreview.alpha = 1

        }

        convertButtonOutlet.layer.masksToBounds = false

        if traitCollection.userInterfaceStyle == .dark {
            //Dark Mode

            convertButtonOutlet.backgroundColor = UIColor(
                red: 0.957, green: 0.957, blue: 0.957, alpha: 1.0)
            convertButtonOutlet.layer.shadowColor = UIColor.white.cgColor
            convertButtonOutlet.layer.shadowOffset = CGSize(width: 0, height: 5)
            self.convertButtonOutlet.layer.shadowOpacity = 0.4
            self.convertButtonOutlet.layer.shadowRadius = 14
            self.MainView.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.00)
            self.textView.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.00)

        } else {
            //Light Mode

            CloseTextButtonOutlet.setTitleColor(
                UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.00), for: .normal)
            printButtonOutlet.setTitleColor(
                UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.00), for: .normal)
            convertButtonOutlet.backgroundColor = UIColor(
                red: 0.10, green: 0.10, blue: 0.10, alpha: 1.00)
            convertButtonOutlet.setTitleColor(
                UIColor(red: 0.957, green: 0.957, blue: 0.957, alpha: 1.0), for: .normal)
            convertButtonOutlet.layer.shadowColor = UIColor.black.cgColor
            convertButtonOutlet.layer.shadowOffset = CGSize(width: 0, height: 5)
            convertButtonOutlet.layer.shadowRadius = 8
            convertButtonOutlet.layer.shadowOpacity = 0.6

        }

        // setup camera
        setUpCamera()
        textView.isHidden = true

        printButtonOutlet.isHidden = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }

    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480) { success in

            if success {
                // add preview view on the layer
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }

                // start video preview when setup is done
                self.videoCapture.start()

            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }

    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds

    }

    @IBAction func printButton(_ sender: Any) {

        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Reverse Text Print"
        printController.printInfo = printInfo
        let formatter = UIMarkupTextPrintFormatter(markupText: self.textView.text)
        formatter.perPageContentInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        printController.printFormatter = formatter
        printController.present(animated: true)
    }

    @IBAction func closeTextButton(_ sender: Any) {
        convertButtonOutlet.isEnabled = false
        CloseTextButtonOutlet.isEnabled = false
        wordsArray.removeAll()

        UITextView.animate(withDuration: 0.5) {
            self.textView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.41) {

            self.textView.isHidden = true

        }
        self.convertButtonOutlet.isEnabled = true

        UIView.animate(withDuration: 0.5) {
            self.printButtonOutlet.alpha = 0

        }

        self.printButtonOutlet.isEnabled = false
    }

    func reverseSentence(_ sentence: String) -> String {
        //create array of words
        let words = sentence.components(separatedBy: " ")
        var result = ""
        //append words to result with a space
        for word in words.reversed() {
            result += "\(word) "
        }
        return result
    }

    func stringHasNumber(_ string: String) -> Bool {
        for character in string {
            if character.isNumber {
                return true
            }
        }
        return false
    }

    @IBAction func convertButton(_ sender: Any) {

        CloseTextButtonOutlet.isEnabled = false

        self.printButtonOutlet.isHidden = false
        self.printButtonOutlet.isEnabled = true
        self.printButtonOutlet.alpha = 0
        convertButtonOutlet.isEnabled = false

        if drawingView.visionText?.blocks == nil {
            textView.text = "oN txeT dezingoceR"
            textView.isHidden = false
            self.textView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            UITextView.animate(withDuration: 0.5) {
                self.textView.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.printButtonOutlet.alpha = 1

            }
            self.CloseTextButtonOutlet.isEnabled = true
            self.convertButtonOutlet.isEnabled = true
            return
        }
        for block in drawingView.visionText!.blocks {

            let lines: [VisionTextLine] = block.lines
            for line in lines {

                let elements: [VisionTextElement] = line.elements
                for element in elements {

                    var text = element.text
                    if text.isNumeric {

                        self.wordsArray.append(text)

                    }

                    else {
                        text.enumerateSubstrings(in: text.startIndex..., options: .byWords) {
                            _, range, _, _ in
                            text.replaceSubrange(range, with: text[range].reversed())
                            self.wordsArray.append(text)
                        }
                    }
                }
            }

            textView.text = wordsArray.joined(separator: " ")
            textView.isHidden = false
            self.textView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            UITextView.animate(withDuration: 0.5) {
                self.textView.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.printButtonOutlet.alpha = 1

            }
            self.CloseTextButtonOutlet.isEnabled = true

        }

    }

}

// MARK: - VideoCaptureDelegate
extension MainVideoViewController: VideoCaptureDelegate {
    func videoCapture(
        _ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime
    ) {
        // the captured image from camera is contained on pixelBuffer
        if !self.isInference, let pixelBuffer = pixelBuffer {
            // start of measure

            self.isInference = true

            // predict!
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

extension MainVideoViewController {
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        let ciimage: CIImage = CIImage(cvImageBuffer: pixelBuffer)
        // crop found word
        let ciContext = CIContext()
        guard let cgImage: CGImage = ciContext.createCGImage(ciimage, from: ciimage.extent) else {
            self.isInference = false
            // end of measure

            return
        }
        let uiImage: UIImage = UIImage(cgImage: cgImage)
        let visionImage = VisionImage(image: uiImage)
        textRecognizer.process(visionImage) { (features, error) in

            // this closure is called on main thread
            if error == nil, let features: VisionText = features {
                self.drawingView.imageSize = uiImage.size

                self.drawingView.visionText = features

            } else {
                self.drawingView.imageSize = .zero
                self.drawingView.visionText = nil
            }

            self.isInference = false
            // end of measure

        }
    }

}

extension String {
    var isNumeric: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
}
