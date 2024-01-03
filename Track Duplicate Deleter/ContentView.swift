import SwiftUI
import AppKit
import AVFoundation

struct SongMetadata:Identifiable {
    let id = UUID()
    let filename: String
    let title: String
    let artist: String
    let album: String
    let length: String
}

struct ContentView: View {
    @State private var dirPath: String = ""
    @State private var deleteConfimed: Bool = false
    @State private var duplicates: [String] = []
    @State private var files: [String] = []
    @State private var songMetadataList: [SongMetadata] = []
    @State private var selection: Set<SongMetadata.ID> = []
    @State private var sortOrder = [KeyPathComparator(\SongMetadata.title, order: .reverse)]

    var body: some View {
        
        VStack {
            Text("Song Duplicate Deleter").bold().padding(.top)
            HStack {
                TextField("Enter Music Directory Path:", text: $dirPath).padding(.leading)
                Button("Browse") {
                    showFilePicker()
                }
                .padding(.trailing)
            }
            
            Text("Track List:").padding(.top)
            
            Table(songMetadataList, selection: $selection, sortOrder: $sortOrder) {
                        TableColumn("File", value: \.filename)
                        TableColumn("Title", value: \.title)
                        TableColumn("Artist", value: \.artist)
                        TableColumn("Album", value: \.album)
                        TableColumn("Length", value: \.length)
            }.onChange(of: sortOrder) { newOrder in
                songMetadataList.sort(using: newOrder) }
                    
            HStack {
                Button("Find Duplicate Tracks") {
                    findDuplicates()
                }.padding()
                
                Button("Delete Duplicates") {
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
                let metadata = extractMetadata(from: filePath, filename: fileName)
                if let validMetadata = metadata {
                    songMetadataList.append(validMetadata)
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
            let metadata = asset.metadata
            var title = ""
            var artist = ""
            var album = ""
            var length = ""
            let duration = getDuration(from: asset)
            
            for item in metadata {
                        if let commonKey = item.commonKey, let value = item.value as? String {
                            // Step 5: Use a switch statement to handle different common keys
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
            return SongMetadata(filename: filename, title: title, artist: artist, album: album, length: duration)
            
        }
        catch {
                // Step 7: Handle any errors during metadata extraction
                print("Error extracting metadata: \(error.localizedDescription)")
                return nil
            }
        }
    
    func getDuration(from asset:AVAsset) -> String {
        let duration = asset.duration
        let durationInSeconds = CMTimeGetSeconds(duration)
        let minutes = Int(durationInSeconds / 60)
                    let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
                    
                    return String(format: "%02d:%02d", minutes, seconds)
    }

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
