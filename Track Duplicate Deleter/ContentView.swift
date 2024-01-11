import SwiftUI
import AppKit
import AVFoundation

struct SongMetadata:Identifiable {
    let id = UUID()
    let filename: String
    let title: String
    let artist: String
    let album: String
    let duration: String
    let format: String
    let size: String
    let bitrate: String
}

struct ContentView: View {
    @State private var dirPath: String = ""
    @State private var deleteConfimed: Bool = false
    @State private var duplicates: [String] = []
    @State private var files: [String] = []
    @State private var songFileExtensions = ["mp3", "wav", "flac", "w4a"]
    @State private var songMetadataList: [SongMetadata] = []
    @State private var selection: Set<SongMetadata.ID> = []
    @State private var sortOrder = [KeyPathComparator(\SongMetadata.title, order: .reverse)]

    var body: some View {
        
        VStack {
            Text("🎵 Song Track Duplicate Deleter 🎶").bold().padding()
            Text("Music Folder Location").padding(.leading).frame(maxWidth: .infinity, alignment: .leading)
                
            HStack {
                TextField("Enter Music Directory Path:", text: $dirPath).padding(.leading)
                Button("📁 Browse") {
                    showFilePicker()
                }
                .padding(.trailing)
            }.padding(.bottom)
            
            Text("Track List").padding( .leading).frame(maxWidth: .infinity, alignment: .leading)
            
            Table(songMetadataList, selection: $selection, sortOrder: $sortOrder) {
                        TableColumn("File", value: \.filename)
                        TableColumn("Title", value: \.title)
                        TableColumn("Artist", value: \.artist)
                        TableColumn("Album", value: \.album)
                        TableColumn("Duration", value: \.duration)
                    TableColumn("Format", value: \.format)
                        TableColumn("Size", value: \.size)
                        TableColumn("Bitrate", value: \.bitrate)
            }.onChange(of: sortOrder) { newOrder in
                songMetadataList.sort(using: newOrder) }
                    
            HStack {
                Button("🔎  Find Duplicate Tracks") {
                    findDuplicates()
                }.padding()
                
                Button("🗑️  Delete Duplicates") {
                    deleteDuplicates();
                }.padding()
                    .alert(isPresented: $deleteConfimed) {
                    Alert(
                        title: Text("Deletion Complete"),
                        message: Text("\(duplicates.count) Duplicate Tracks have been deleted."),
                        dismissButton: .default(Text("OK"))
                    )
            }
            
            }.padding(.trailing)
        }
    }
    

    // Functions
    func showFilePicker() {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false

            panel.begin { response in
                if response == .OK {
                    if let url = panel.url {
                        dirPath = url.path
                        updateMetadataList()
                    }
                }
            }
        }
    }
    
    func updateMetadataList() {
        do {
            let fileManager  = FileManager.default
            let folderContents = try fileManager.contentsOfDirectory(atPath: dirPath)
            for fileName in folderContents {
                let filePath = URL(fileURLWithPath: dirPath + "/" + fileName)
                
//                Check is file is audio format
                let fileExtension = filePath.pathExtension.lowercased()
                
                if songFileExtensions.contains(fileExtension) {
                    let metadata = extractMetadata(from: filePath, filename: fileName)
                    if let validMetadata = metadata {
                        songMetadataList.append(validMetadata)
                    }
                }
                
            }
        }
        catch {
            print("Error listing files: \(error.localizedDescription)")
        }
    }
        
    func extractMetadata(from filePath: URL, filename: String) -> SongMetadata? {
        do {
            let asset = AVAsset(url: filePath)
            let audioFile = try AVAudioFile(forReading: filePath)
            let metadata = asset.metadata
            let duration = getDuration(from: asset)
            let fileSize = calculateFileSize(forURL: filePath)
            let formattedFileSize = "\(round(fileSize * 100) / 100.0) MB"
            let formattedDuration = formatMinSec(durationInSeconds: duration)
            let bitrate = getAudioBitrate(fileSizeMB: fileSize, durationSec: duration)
            let format = filePath.pathExtension.lowercased()

            var title = ""
            var artist = ""
            var album = ""

            for item in metadata {
                if let commonKey = item.commonKey, let value = item.value as? String {
                    switch commonKey {
                    case .commonKeyTitle:
                        title = value
                    case .commonKeyArtist:
                        artist = value
                    case .commonKeyAlbumName:
                        album = value
                    default:
                        break
                    }
                }
            }

            return SongMetadata(filename: filename, title: title, artist: artist, album: album, duration: formattedDuration, format: format, size: formattedFileSize , bitrate: bitrate)

        } catch {
            print("Error extracting metadata: \(error.localizedDescription)")
            return nil
        }
    }


    func calculateFileSize(forURL url: Any) -> Double {
        var fileURL: URL?
        var fileSize: Double = 0.0
        if (url is URL) || (url is String)
        {
            if (url is URL) {
                fileURL = url as? URL
            }
            else {
                fileURL = URL(fileURLWithPath: url as! String)
            }
            var fileSizeValue = 0.0
            try? fileSizeValue = (fileURL?.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).allValues.first?.value as! Double?)!
            if fileSizeValue > 0.0 {
                fileSize = (Double(fileSizeValue) / (1024 * 1024))
            }
        }
        return fileSize
    }



    
    func getDuration(from asset:AVAsset) -> Double {
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        return durationInSeconds
    }
    
    func formatMinSec(durationInSeconds: Double) -> String {
        let minutes = Int(durationInSeconds / 60)
                    let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
                    
                    return String(format: "%02d:%02d", minutes, seconds)
    }

    
    func getAudioBitrate(fileSizeMB: Double, durationSec: Double) -> String {
            do {
                // convert MB to kilobits
                var kbpsFinal:Int
                let kilobits = fileSizeMB * 8000
                let kbps = kilobits / durationSec
                let kbpsRounded = Int(kbps)
                switch kbpsRounded {
                case 1...40: kbpsFinal = 32
                case 41...70: kbpsFinal = 64
                case 71...109: kbpsFinal = 96
                case 110...150: kbpsFinal = 128
                case 150...215: kbpsFinal = 192
                case 216...270: kbpsFinal = 256
                case 271...355: kbpsFinal = 320
                    
                default:
                    kbpsFinal = kbpsRounded
                }
                return "\(kbpsFinal) kbps"
            }
            catch {
                print("Error: \(error.localizedDescription)")
                return "0 kbps"
            }
            
        }


//
//
//    func getAudioBitrate(filePath: URL) -> String {
//        do {
//            // Get the audio file size in bytes
//            let audioFileData = try Data(contentsOf: filePath)
//            let audioFileSizeBytes = UInt64(audioFileData.count)
//            
//            // Get the audio duration in seconds
//            let asset = AVURLAsset(url: filePath)
//            let durationSeconds = CMTimeGetSeconds(asset.duration)
//            
//            // Calculate the bitrate in bps
//            let audioBitrateBps = Double(audioFileSizeBytes * 8) / durationSeconds
//            
//            // Convert bps to kbps and round to nearest integer
//            let audioBitrateKbps = Int(audioBitrateBps / 1000)
//            
//            return "\(audioBitrateKbps) kbps"
//        } catch {
//            print("Error: \(error.localizedDescription)")
//            return "Unknown"
//        }
//    }


    

    func findDuplicates() {
        do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: dirPath)
                
                // Print the list of files in the selected directory
                print("Files in \(dirPath):")
                for file in contents {
                    print(file)
                }
                
                // Implement logic to find duplicates and update the 'duplicates' array
                // ...

                // For testing, let's simulate finding duplicates and updating the count
                duplicates = ["Track1", "Track2", "Track3"]

                
            } catch {
                print("Error listing files: \(error.localizedDescription)")
            }
    }
    
    func deleteDuplicates() {
        // Set deleteConfirmed to true after finding duplicates
        deleteConfimed = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
