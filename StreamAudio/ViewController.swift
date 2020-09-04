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
    @IBOutlet weak var recordVolumeStep: UIStepper!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playProgressView: UIView!
    @IBOutlet weak var downloadedProgress: UIView!
    lazy var streamer: KTV = { [weak self] in
        let s = KTV()
        s.delegate = self
        return s
    }()
    var player = KTVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playProgressView.frame = CGRect(x: 0, y: 0, width: 0, height: playProgressView.superview?.frame.size.height ?? 0)
        downloadedProgress.frame = CGRect(x: 0, y: 0, width: 0, height: playProgressView.superview?.frame.size.height ?? 0)

        let url = URL(string: "http://qfgraevqo.hn-bkt.clouddn.com/%E5%94%90%E6%9C%9D%20-%20%E5%9B%BD%E9%99%85%E6%AD%8C.mp3")
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
        player.playOrStop()
        player.localURL = URL(fileURLWithPath: streamer.recordvVoiceSavePath())
        player.playOrStop()
    }
    
    @IBAction func clickProduct(_ sender: Any) {
        player.playOrStop()
        player.localURL = URL(fileURLWithPath: streamer.mixerAudioSavePath())
        player.playOrStop()
    }
    @IBAction func recordReverbChange(_ sender: Any) {
        let reverb = Int(recordReverbStep.value >= 12 ? 12 : recordReverbStep.value)
        print("伴奏混响: ", recordReverbStep.value)
        streamer.micReverb.loadFactoryPreset(AVAudioUnitReverbPreset(rawValue: reverb)!)
    }
    
    @IBAction func recordDelayChange(_ sender: Any) {
        let value = Float(recordDelay.value / 50)
        print("伴奏延迟: ", value)
        streamer.micdelay.delayTime = TimeInterval(value)
    }
    
    @IBAction func recordVolumeChange(_ sender: Any) {
        let volume = recordVolumeStep.value
        print("伴奏音量:", volume)
        streamer.updateVoiceVolume(CGFloat(volume))
        
    }
    @IBAction func songVolumeChange(_ sender: Any) {
        if let step = sender as? UIStepper {
            print("伴奏音量: ", CGFloat(step.value))
            streamer.updateSongVolume(CGFloat(step.value))
        }
    }
    
    @IBAction func productReverbChange(_ sender: Any) {
        if let step = sender as? UIStepper {
            print("成品混响: ", CGFloat(step.value))
            player.songReverb.loadFactoryPreset(AVAudioUnitReverbPreset(rawValue: Int(step.value))!)
        }
    }
    @IBAction func productDelayChange(_ sender: Any) {
        if let step = sender as? UIStepper {
            print("成品延迟: ", CGFloat(step.value))
            player.songDelay.delayTime = step.value
        }
        
    }
    @IBAction func productRateChange(_ sender: Any) {
        if let step = sender as? UIStepper {
            print("成品速度: ", CGFloat(step.value))
            player.songRate.rate = Float(step.value)
        }
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

