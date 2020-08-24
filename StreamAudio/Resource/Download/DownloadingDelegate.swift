//
//  DownloadingDelegate.swift
//  StreamAudio
//
//  Created by leven on 2020/8/21.
//  Copyright © 2020 leven. All rights reserved.
//


import Foundation

public protocol DownloadingDelegate: class {
    
    func download(_ download: Downloading, changeState state: DownloadingState)
    
    func download(_ download: Downloading, completedWithError error: Error?)
    
    func download(_ download: Downloading, didReceivedData data: Data, progress: Float)
    
}
