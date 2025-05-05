import SwiftUI
import AVFoundation
import MediaPlayer

class RadioPlayer: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var currentStation = stations[0] {
        didSet { loadStation() }
    }
    @Published var title = ""
    @Published var artist = ""
    @Published var artworkURL: URL?
    @Published var isPlaying = false
    @Published var isLoading = false

    // MARK: - Private Properties
    private var player: AVPlayer?
    private var metadataTimer: Timer?

    // MARK: - Init
    override init() {
        super.init()
        loadStation()
        setupRemoteCommandCenter()
    }

    // MARK: - Playback Controls
    func loadStation() {
        stop()
        isLoading = true

        guard let url = URL(string: currentStation.streamURL) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }

        player = AVPlayer(url: url)
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.initial, .new], context: nil)

        player?.play()
        isPlaying = true
        updateNowPlayingInfo(title: title, artist: artist, artworkURL: artworkURL)

        fetchMetadata()
        startMetadataTimer()
    }

    func playPause() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
            isLoading = false  // 🧹 Stop spinner if user pauses early
        } else {
            isLoading = true
            player.addObserver(self, forKeyPath: "timeControlStatus", options: [.initial, .new], context: nil)
            player.play()
            isPlaying = true
            updateNowPlayingInfo(title: title, artist: artist, artworkURL: artworkURL)
        }
    }


    func stop() {
        player?.pause()
        isPlaying = false
        isLoading = false
        metadataTimer?.invalidate()
        player?.removeObserver(self, forKeyPath: "timeControlStatus", context: nil)
    }

    // MARK: - Remote Command Center
    private func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.player?.play()
            self?.isPlaying = true
            self?.updateNowPlayingInfo(title: self?.title ?? "", artist: self?.artist ?? "", artworkURL: self?.artworkURL)
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.player?.pause()
            self?.isPlaying = false
            return .success
        }
    }

    // MARK: - Metadata Observation
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus",
           let player = object as? AVPlayer,
           player.timeControlStatus == .playing {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    // MARK: - Now Playing Info
    func updateNowPlayingInfo(title: String, artist: String, artworkURL: URL?) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist
        ]

        if let artworkURL = artworkURL {
            URLSession.shared.dataTask(with: artworkURL) { data, _, _ in
                if let data = data,
                   let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                }

                DispatchQueue.main.async {
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                }
            }.resume()
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    // MARK: - Metadata Polling
    private func startMetadataTimer() {
        metadataTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            self.fetchMetadata()
        }
    }

    func fetchMetadata() {
        guard let url = URL(string: currentStation.statusURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let track = json["current_track"] as? [String: Any] else { return }

            DispatchQueue.main.async {
                let fullTitle = track["title"] as? String ?? ""
                let parts = fullTitle.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
                self.artist = parts.first?.trimmingCharacters(in: .whitespaces) ?? ""
                self.title = parts.count > 1 ? parts.last?.trimmingCharacters(in: .whitespaces) ?? "" : ""

                if let artworkString = track["artwork_url_large"] as? String,
                   let artwork = URL(string: artworkString) {
                    self.artworkURL = artwork
                }

                self.updateNowPlayingInfo(title: self.title, artist: self.artist, artworkURL: self.artworkURL)
            }
        }.resume()
    }
}

struct ContentView: View {
    @StateObject var player = RadioPlayer()

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .top) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .padding(.top, 36)

                HStack {
                    Spacer()
                    Button(action: player.loadStation) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color(red: 0.0, green: 0.6, blue: 1.0))
                    }
                    .padding(.trailing, 26)
                    .padding(.top, 40)
                }
            }

            Text("The #1 Radio Station for Progressive Rock")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)


            Divider()
                .background(Color.white.opacity(1.0))
                .padding(.vertical, 6)

            Picker("", selection: $player.currentStation) {
                ForEach(stations, id: \.name) { station in
                    Text(station.name).tag(station)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .colorScheme(.dark)
            .padding(.horizontal)
            
            Spacer().frame(height: 6)

            ZStack {
                if let artworkURL = player.artworkURL {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .empty:
                            Color.black.frame(height: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                        case .failure:
                            Image(systemName: "photo")
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .foregroundColor(.gray)
                }

                if player.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(3.0)
                }
            }

            Text(player.title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(player.artist)
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: player.playPause) {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)
            }
            .padding(.top, 12)

            Spacer()
        }
        .padding()
        .background(Color.black)
        .ignoresSafeArea()
    }
}

