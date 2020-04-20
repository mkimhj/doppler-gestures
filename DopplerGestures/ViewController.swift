//
//  ViewController.swift
//  DopplerGestures
//
//  Created by Maruchi Kim on 4/14/20.
//  Copyright © 2020 Maruchi Kim. All rights reserved.
//

import UIKit
import AudioKit
import Charts

class ViewController: UIViewController {
    
    @IBOutlet weak var frequencyPlotView: LineChartView!
    @IBOutlet weak var frequencyLabel: UILabel!
    
    let FFT_SIZE       = 512
    var oscillator     = AKOscillator()
    var mic            = AKMicrophone()
    var micBooster     = AKBooster()
    var tracker        = AKFrequencyTracker()
    var audioFormat    = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)
    var highPassFilter = AKHighPassFilter()
    var fftOutput      = AKFFTTap(AKBooster())
    var gestureString  = String()
    var runLoopTimeMs = 0.0
    var gestureDetectedTimeMs = 0.0
    var lastAmplitudeArray = [Double]()
    var gestureCounter = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.frequencyPlotView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        self.frequencyPlotView.rightAxis.enabled = false
        self.frequencyPlotView.leftAxis.axisMinimum = -240
        self.frequencyPlotView.leftAxis.axisMaximum = -120
        self.frequencyPlotView.xAxis.axisMinimum = 17000
        self.frequencyPlotView.xAxis.axisMaximum = 19000
        

        AKSettings.playbackWhileMuted = true
        AKSettings.audioInputEnabled = true
        oscillator.amplitude = 1
        oscillator.frequency = 18000
        mic = AKMicrophone(with: audioFormat)
        micBooster = AKBooster(mic, gain:1)
//        highPassFilter = AKHighPassFilter(mic, cutoffFrequency: 15000, resonance: 0)
        fftOutput = AKFFTTap.init(micBooster)
        
//        tracker = AKFrequencyTracker(highPassFilter)

        AudioKit.output = AKMixer(micBooster, oscillator)
        
        do {
            try AudioKit.start()
            oscillator.start()
            micBooster.start()
//            highPassFilter.start()
//            tracker.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        
        NSLog("Audio Kit started")

        Timer.scheduledTimer(timeInterval: 0.01,
                             target: self,
                             selector: #selector(ViewController.runLoop),
                             userInfo: nil,
                             repeats: true)
    }
    
    @objc func runLoop() {
        var logAmplitudeArray = [Double]()
        runLoopTimeMs += 0.01
        
        for i in stride(from:0, to:(FFT_SIZE), by: 2) {
            let real = fftOutput.fftData[i]
            let imag = fftOutput.fftData[i+1]
            let binMagnitude = 2.0 * sqrt(real * real + imag * imag)/self.FFT_SIZE
            let logAmplitude = (20.0 * log10(binMagnitude))
            logAmplitudeArray.append(logAmplitude)
        }
        
//        if (runLoopTimeMs - gestureDetectedTimeMs > 0.01) {
            
//            PULL
        if (((logAmplitudeArray[207] - logAmplitudeArray[208]) > 4) && (((logAmplitudeArray[210] - logAmplitudeArray[211]) > 1))) { // PULL
            if (gestureString == "PUSH") {
                gestureCounter = 0
            }
            gestureString = "PULL"
            gestureDetectedTimeMs = runLoopTimeMs
            gestureCounter+=1
            NSLog("PULL")
            NSLog("PULL %f %f", logAmplitudeArray[207], logAmplitudeArray[207] - logAmplitudeArray[208])
            NSLog("PUSH %f %f", logAmplitudeArray[210], logAmplitudeArray[210] - logAmplitudeArray[211])
            NSLog("\n")
        }
        
//            PUSH
        else if (((logAmplitudeArray[210] - logAmplitudeArray[211]) < -15)) { // PUSH
            if (gestureString == "PULL") {
                gestureCounter = 0
            }
            gestureString = "PUSH"
            gestureDetectedTimeMs = runLoopTimeMs
            gestureCounter+=1
            NSLog("PUSH")
            NSLog("PULL %f %f", logAmplitudeArray[207], logAmplitudeArray[207] - logAmplitudeArray[208])
            NSLog("PUSH %f %f", logAmplitudeArray[210], logAmplitudeArray[210] - logAmplitudeArray[211])
            NSLog("\n")
        }
//        }
        
        else {
            gestureCounter = 0
                
        }
        
        setFrequencyPlotValues(256, frequencies:logAmplitudeArray)
        
        if (gestureCounter >= 2) {
            let boldAttribute = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 36.0)!]
            let boldText = NSAttributedString(string: gestureString, attributes: boldAttribute)
            frequencyLabel.attributedText = boldText
            frequencyLabel.textAlignment = NSTextAlignment.center
            
            lastAmplitudeArray = logAmplitudeArray
        }
    }
    
    func setFrequencyPlotValues(_ count: Int = 256, frequencies:[Double]) {
        let values = (0..<count).map { (i) -> ChartDataEntry in
//            let val = Double(arc4random_uniform(UInt32(count)) + 3)
            return ChartDataEntry(x: Double((44100 / FFT_SIZE)*(i)), y:frequencies[i])
        }

        let set1 = LineChartDataSet(entries: values, label: "Frequency Plot")
        set1.drawCirclesEnabled = false
        set1.lineWidth = 2
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(false)
        


        
        
        self.frequencyPlotView.data = data
        
        
        
    }
}
