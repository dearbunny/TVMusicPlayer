//
//  ViewController.swift
//  MusicPlayer音樂播放器
//
//  Created by Rose on 2021/4/28.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
    //播放器進度
    @IBOutlet weak var playbackSlider: UISlider!
    //歌曲名＋歌手
    @IBOutlet weak var songName: UILabel!
    //專輯名
    @IBOutlet weak var albumName: UILabel!
    //專輯圖片
    @IBOutlet weak var albumImage: UIImageView!
    // 播放/暫停按鈕
    @IBOutlet weak var controlButton: UIButton!
    // 音量
    @IBOutlet weak var volumeSlider: UISlider!
    // 時間
    @IBOutlet weak var nowTime: UILabel!
    @IBOutlet weak var allTime: UILabel!
    
    // album.swift 音樂資料庫 陣列
    var songArray:[album]! = [album]()
    // 播放索引（第幾首歌）
    var playIndex = 0
    // 播放器
    let player = AVQueuePlayer()
    //重複播放
    var looper: AVPlayerLooper?
    // 當前播放的物件 Album Obiect
    var currentSongObj:album?
    // 播放/暫停按鈕圖案
    let playIcon = UIImage(systemName: "play.circle.fill")
    let pauseIcon = UIImage(systemName: "pause.circle.fill")
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //製作漸層
        let gradientView = UIView(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor(red: 161/255, green: 84/255, blue: 110/155, alpha: 0.8).cgColor,
            UIColor(red: 18/255, green: 18/255, blue: 18/155, alpha: 1).cgColor
        ]
        //漸層位置
        gradientLayer.locations = [0, 0.2]
        view.layer.insertSublayer(gradientLayer, at: 0)
        

        // 自訂Slider圖案
        playbackSlider.setThumbImage(UIImage(named: "miniThumb"), for: .normal)
        volumeSlider.setThumbImage(UIImage(named: "miniThumb"), for: .normal)
        
        //  音樂資料庫
        songArray.append(album(albumName:"天乩之白蛇傳說 插曲",albumImage:"千年-金志文 吉克雋逸",songName:"千年-金志文 吉克雋逸"))
        songArray.append(album(albumName:"三生三世十里桃花 片尾曲",albumImage:"涼涼-楊宗緯 張碧晨",songName:"涼涼-楊宗緯 張碧晨"))
        songArray.append(album(albumName:"芸汐傳 片尾曲",albumImage:"嘆雲兮-鞠婧禕",songName:"嘆雲兮-鞠婧禕"))
        songArray.append(album(albumName:"網遊蜀山縹緲錄 主題曲",albumImage:"渡紅塵-張碧晨",songName:"渡紅塵-張碧晨"))
        songArray.append(album(albumName:"扶搖 主題曲",albumImage:"傲紅塵-尤長靖",songName:"傲紅塵-尤長靖"))
        songArray.shuffle()
        
        //  設定背景&鎖定播放
        setupRemoteTransportControls()
        
        //  播放音樂
        playSong()
        //執行現在播放的秒數
        CurrentTime()
        
        //  播完後，繼續播下一首
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { (_) in
            self.playIndex = self.playIndex + 1
            self.playSong()
            //  移除監聽
            self.player.removeTimeObserver(self.timeObserver)

        }
        
    }
    
    //  播放音樂
    func playSong(){
        if playIndex < songArray.count{
            if playIndex < 0{
                playIndex = songArray.count - 1
            }
            
            let albumObj = songArray[playIndex]
            currentSongObj = albumObj
            if albumObj != nil {
                let albumName:String = albumObj.albumName
                let songName:String = albumObj.songName
                let imageName:String = albumObj.albumImage
                
                //  設定Label顯示
                self.songName.text = songName
                self.albumName.text = albumName
                
                //  設定Image圖片顯示
                albumImage.image = UIImage(named: imageName)
                
                //  載入歌曲檔案，取得在手機APP中實際位置
                let fileUrl = Bundle.main.url(forResource: songName, withExtension: "mp3")!
                // 建立播放項目
                let playerItem = AVPlayerItem(url: fileUrl)
                //  先移除player播放器內現有的Item，這個很重要，不然壞掉的時候他就會一直亂播同首歌
                player.removeAllItems()
                // 放入現在要播放的Item
                player.replaceCurrentItem(with: playerItem)
                // 指定音量，這部分不太有作用，因為會按照使用者系統指定的音量來播放
                player.volume = 0.5
                looper = AVPlayerLooper(player: player, templateItem: playerItem)
                
                //總時間顯示
                let duration = CMTimeGetSeconds(playerItem.asset.duration)
                allTime.text = formatConversion(time: duration)
                

                //  重置slider和播放軌道
                playbackSlider.setValue(Float(0), animated: true)
                let targetTime:CMTime = CMTimeMake(value: Int64(0), timescale: 1)
                player.seek(to: targetTime)
                
                //  播放
                player.play()
                
                //  更新slider時間value
                let Duration : CMTime = playerItem.asset.duration
                let seconds : Float64 = CMTimeGetSeconds(Duration)
                playbackSlider.minimumValue = 0
                playbackSlider.maximumValue = Float(seconds)

                //  事件監聽：進度條
                addProgressObserver(playerItem:playerItem)
                
                //  設定播放按鈕圖案
                controlButton.setImage(pauseIcon, for: UIControl.State.normal)
                
                // 設定背景當前播放資訊
                setupNowPlaying()
            }
        }else{
            playIndex = 0
            playSong()
        }
        }
    
    //  播放/暫停
    // 透過圖片來判斷或者player.rate來判斷歌曲是否正在播放中，如果rate==0代表暫停中，若rate==1則代表歌曲播放中。
    @IBAction func playButton(_ sender: UIButton) {
        let imageName = controlButton.imageView?.image
        if imageName == playIcon{
            if player.rate == 0{
                player.play()
                controlButton.setImage(pauseIcon, for: UIControl.State.normal)
            }
        }else if imageName == pauseIcon{
            if player.rate == 1{
                player.pause()
                controlButton.setImage(playIcon, for: UIControl.State.normal)
            }
        }
    }
    
    // 事件監聽、更新進度條
    var timeObserver: Any!
    func addProgressObserver(playerItem:AVPlayerItem){
        //  每秒執行一次
        timeObserver =  player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: Int64(1.0), timescale: Int32(1.0)), queue: DispatchQueue.main) { [weak self](time: CMTime) in
            //  已跑秒數
            let currentTime = CMTimeGetSeconds(time)
            //  歌曲秒數
            let totalTime = CMTimeGetSeconds(playerItem.duration)
            //  更新進度條
            print("正在播放",currentTime , "/" , "全部時間" , totalTime)
            self?.playbackSlider.setValue(Float(currentTime), animated: true)
        }
    }
    
    // 下一首
    @IBAction func nextButton(_ sender: UIButton) {
        playIndex = playIndex + 1
        playSong()
    }
    
    
    // 上一首
    @IBAction func backButton(_ sender: UIButton) {
        playIndex = playIndex - 1
        playSong()
    }
    //  設定背景&鎖定播放
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0.0 {
                self.player.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    //  設定背景播放的歌曲資訊
    func setupNowPlaying() {
        // Define Now Playing Info
        let songName:String = (self.currentSongObj?.songName)!
        let albumName:String = (self.currentSongObj?.albumName)!
        let albumImage:String = (self.currentSongObj?.albumImage)!
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = songName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumName

        if let image = UIImage(named: albumImage) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.asset.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    //  拖曳slider進度，要設定player播放軌道
    @IBAction func playbackChangSlider(_ sender: UISlider) {
        //  slider移動的位置
        let seconds : Int64 = Int64(playbackSlider.value)
        //  計算秒數
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        //  設定player播放進度
        player.seek(to: targetTime)
        
        //  如果player暫停，則繼續播放
        if player.rate == 0{
            player.play()
            controlButton.setImage(pauseIcon, for: UIControl.State.normal)
        }
    }
    
    //現在播放的秒數
    func CurrentTime(){
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main, using: { (CMTime) in
            if self.player.currentItem?.status == .readyToPlay {
                let currentTime = CMTimeGetSeconds(self.player.currentTime())
                //讓Slider跟著連動
                self.playbackSlider.value = Float(currentTime)
                //文字更改
                self.nowTime.text = self.formatConversion(time: currentTime)
                self.allTime.text = "\(self.formatConversion(time: Float64(self.playbackSlider.maximumValue - self.playbackSlider.value)))"
            }
        })
    }
    // 秒數顯示
    func formatConversion(time:Float64) -> String {
        let songLength = Int(time)
        let minutes = Int(songLength / 60) //為分鐘數
        let seconds = Int(songLength % 60) //為秒數
        var time = ""
        if minutes < 10 {
          time = "0\(minutes):"
        } else {
          time = "\(minutes)"
        }
        if seconds < 10 {
          time += "0\(seconds)"
        } else {
          time += "\(seconds)"
        }
        return time
    }
    
    // 音量
    @IBAction func changeVolume(_ sender: UISlider) {
        player.volume = sender.value
    }
    
    //重複播放
    
    
    
}

