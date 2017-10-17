//
//  RecordingsViewController.swift
//  SimpleRecorder
//
//  Created by Sergey Yuryev on 13/10/2017.
//  Copyright © 2017 syuryev. All rights reserved.
//

let kSimpleRecordingRecordingsReusableCell = "kSimpleRecordingRecordingsReusableCell"

import UIKit
import AVFoundation

struct Recording {
    var name: String
    var path: URL
}

protocol RecordingsViewControllerDelegate: class {
    func didStartPlayback()
    func didFinishPlayback()
}

class RecordingsViewController: UIViewController {

    // MARK: - Vars
    
    /// Data with recordings info
    private var recordings: [Recording] = []
    
    /// Audio player
    private var audioPlayer: AVAudioPlayer?
    
    /// Recorder delegate
    weak var delegate: RecordingsViewControllerDelegate?
    
    // MARK: - Outlets
    
    /// Table view with data
    @IBOutlet weak var tableView: UITableView!
    
    /// Fade view
    @IBOutlet weak var fadeView: UIView!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadRecordings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.isPlaying() {
            self.stopPlay()
        }
        super.viewWillDisappear(animated)
    }
    
    
    // MARK: - Setup
    
    private func setup() {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 180, 0)
    }
    
    // MARK: - Data
    
    func loadRecordings() {
        self.recordings.removeAll()
        let filemanager = FileManager.default
        let documentsDirectory = filemanager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let paths = try filemanager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
            for path in paths {
                let recording = Recording(name: path.lastPathComponent, path: path)
                self.recordings.append(recording)
            }
            self.tableView.reloadData()
        } catch {
            print(error)
        }
    }
    
    
    // MARK: - Playback
    
    private func play(url: URL) {
        if let d = self.delegate {
            d.didStartPlayback()
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.caf.rawValue)
        } catch let error as NSError {
            print(error.localizedDescription)
            return
        }
        if let player = self.audioPlayer {
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        }
    }
    
    func stopPlay() {
        if let d = self.delegate {
            d.didFinishPlayback()
        }
        if let paths = self.tableView.indexPathsForSelectedRows {
            for path in paths {
                self.tableView.deselectRow(at: path, animated: true)
            }
        }
        if let player = self.audioPlayer {
            player.pause()
        }
        self.audioPlayer = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch  let error as NSError {
            print(error.localizedDescription)
            return
        }
    }
    
    private func isPlaying() -> Bool {
        if let player = self.audioPlayer {
            return player.isPlaying
        }
        return false
    }
}

extension RecordingsViewController: AVAudioPlayerDelegate {
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let e = error {
            print(e.localizedDescription)
        }
        self.stopPlay()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.stopPlay()
    }
}

extension RecordingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.isPlaying() {
            self.stopPlay()
        }
        let recording = self.recordings[indexPath.row]
        self.play(url: recording.path)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result = self.recordings.count
        if result > 0 {
            self.tableView.isHidden = false
        }
        else {
            self.tableView.isHidden = true
        }
        return result
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: kSimpleRecordingRecordingsReusableCell)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: kSimpleRecordingRecordingsReusableCell)
        }
        let recording = self.recordings[indexPath.row]
        cell?.textLabel?.text = recording.name
        cell?.detailTextLabel?.text = recording.path.absoluteString
        return cell!
        
    }
    
    
}
