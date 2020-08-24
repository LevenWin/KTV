//
//  ViewController.swift
//  StreamAudio
//
//  Created by leven on 2020/8/20.
//  Copyright © 2020 leven. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playProgressView: UIView!
    @IBOutlet weak var downloadedProgress: UIView!
    lazy var streamer: Streamer = { [weak self] in
        let s = Streamer()
        s.delegate = self
        return s
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        playProgressView.frame = CGRect(x: 0, y: 0, width: 0, height: playProgressView.superview?.frame.size.height ?? 0)
        downloadedProgress.frame = CGRect(x: 0, y: 0, width: 0, height: playProgressView.superview?.frame.size.height ?? 0)

        let url = URL(string: "http://qfgraevqo.hn-bkt.clouddn.com/like_me.mp3")
        streamer.url = url
    }
    
    @IBAction func didClickPlay(_ sender: Any) {
        streamer.play()
    }
    
    @IBAction func didClickRecord(_ sender: Any) {
        
    }
    
    @IBAction func didClickStop(_ sender: Any) {
        streamer.pause()
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

