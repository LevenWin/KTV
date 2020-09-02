//
//  ViewController.swift
//  StreamAudio
//
//  Created by leven on 2020/8/20.
//  Copyright © 2020 leven. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {

    @IBOutlet weak var recordReverbStep: UIStepper!
    @IBOutlet weak var recordDelay: UIStepper!
    @IBOutlet weak var recordRateStep: UIStepper!
    
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playProgressView: UIView!
    @IBOutlet weak var downloadedProgress: UIView!
    lazy var streamer: KTV = { [weak self] in
        let s = KTV()
        s.delegate = self
        return s
    }()
    var player: AVAudioPlayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        playProgressView.frame = CGRect(x: 0, y: 0, width: 0, height: playProgressView.superview?.frame.size.height ?? 0)
        downloadedProgress.frame = CGRect(x: 0, y: 0, width: 0, height: playProgressView.superview?.frame.size.height ?? 0)

//        http://qfgraevqo.hn-bkt.clouddn.com/%E5%BE%90%E5%90%91%E4%B8%9C%5B%E9%9F%B3%E4%B9%90%E4%BA%BA%5D-%E5%9B%BD%E9%99%85%E6%AD%8C%EF%BC%88%E9%98%BF%E5%8D%A1%E8%B4%9D%E6%8B%89%E7%89%88%EF%BC%89%28%E4%BC%B4%E5%A5%8F%29.mp3
        let url = URL(string: "http://qfgraevqo.hn-bkt.clouddn.com/%E5%BE%90%E5%90%91%E4%B8%9C%5B%E9%9F%B3%E4%B9%90%E4%BA%BA%5D-%E5%9B%BD%E9%99%85%E6%AD%8C%EF%BC%88%E9%98%BF%E5%8D%A1%E8%B4%9D%E6%8B%89%E7%89%88%EF%BC%89%28%E4%BC%B4%E5%A5%8F%29.mp3")
        streamer.url = url
        do {
            try?          AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.01)
            try?         AVAudioSession.sharedInstance().setCategory(.multiRoute)
            try?         AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        }
    }
    
    @IBAction func didClickPlay(_ sender: Any) {
        streamer.play()
    }

    @IBAction func didClickStop(_ sender: Any) {
        streamer.stop()
    }
    
    @IBAction func clickVoice(_ sender: Any) {
        player?.stop()
        do {
            try? player = AVAudioPlayer(contentsOf: URL(fileURLWithPath: streamer.recordvVoiceSavePath()), fileTypeHint: ".wav")

        }
        player?.play()
    }
    
    @IBAction func clickProduct(_ sender: Any) {
        player?.stop()
        do {
            try? player = AVAudioPlayer(contentsOf: URL(fileURLWithPath: streamer.mixerAudioSavePath()), fileTypeHint: ".wav")
        }
        player?.play()
    }
    @IBAction func recordReverbChange(_ sender: Any) {
        let reverb = Int(recordReverbStep.value >= 12 ? 12 : recordReverbStep.value)
        print("伴奏混响: ", recordReverbStep.value)
        streamer.micReverb.loadFactoryPreset(AVAudioUnitReverbPreset(rawValue: reverb)!)
    }
    
    @IBAction func recordDelayChange(_ sender: Any) {
        let value = Float(recordDelay.value / 50)
        print("伴奏延迟: ", value)
        streamer.delay.delayTime = TimeInterval(value)
    }
    
    @IBAction func recordRateChange(_ sender: Any) {
        let rate = recordRateStep.value
        print("伴奏速度:", rate)
        streamer.recordRate.rate = Float(rate)
    }
    
}
extension ViewController: StreamingDelegate {
    func streamer(_ streamer: Streaming, failedDownloadWithError error: Error, forURL url: URL) {
        
    }
    func streamer(_ streamer: Streaming, updateDownloadProgress progress: Float, forURL url: URL) {
        downloadedProgress.frame = CGRect(x: 0, y: 0,
                                          width: (downloadedProgress.superview?.frame.size.width ?? 0) * CGFloat(progress) ,
                                          height: 6)
    }
    
    func streamer(_ streamer: Streaming, changeState state: StreamingState) {
        
    }
    
    func streamer(_ streamer: Streaming, updateCurrentTime currentTime: TimeInterval) {
        if let duration = streamer.duration, duration > 0, let view = downloadedProgress.superview {
            playProgressView.frame = CGRect(x: 0, y: 0,
                                              width: Double(view.frame.size.width) * currentTime / duration,
                                              height: 6)
        }
    }
    
    func streamer(_ streamer: Streaming, updateDuration duration: TimeInterval) {
        
    }
    
}

