//
//  ViewController.swift
//  DopplerGestures
//
//  Created by Maruchi Kim on 4/14/20.
//  Copyright © 2020 Maruchi Kim. All rights reserved.
//

import UIKit
import AudioKit

class ViewController: UIViewController {
    
    @IBOutlet weak var frequencyLabel: UILabel!
    
//    let FFT_SIZE       : Uint = 512
    let FFT_SIZE       = 512
    var oscillator     = AKOscillator()
    var mic            = AKMicrophone()
    var micBooster     = AKBooster()
    var tracker        = AKFrequencyTracker()
    var audioFormat    = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)
    var highPassFilter = AKHighPassFilter()
    var fftOutput      = AKFFTTap(AKBooster())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        AKSettings.audioInputEnabled = true
        oscillator.amplitude = 1
        oscillator.frequency = 1000
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

        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(ViewController.runLoop),
                             userInfo: nil,
                             repeats: true)
    }
    
    @objc func runLoop() {
        for i in stride(from:0, to:(FFT_SIZE), by: 2) {
            let real = fftOutput.fftData[i]
            let imag = fftOutput.fftData[i+1]
            let binMagnitude = 2.0 * sqrt(real * real + imag * imag)/self.FFT_SIZE
            let logAmplitude = (20.0 * log10(binMagnitude))
            NSLog("%d %f %f", (48000 / FFT_SIZE)*(i/2), binMagnitude, logAmplitude)
        }
        
        
//        frequencyLabel.text = String(format: "%.0f", tracker.frequency)
//        NSLog("%.0f", tracker.frequency)
    }
}
