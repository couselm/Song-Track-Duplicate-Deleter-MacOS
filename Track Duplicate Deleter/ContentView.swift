import SwiftUI
import AppKit
import AVFoundation

struct SongMetadata {
    let title: String
    let artist: String
    let album: String
}

struct ContentView: View {
    @State private var dirPath: String = ""
    @State private var deleteConfimed: Bool = false
    @State private var duplicates: [String] = []
    @State private var files: [String] = []
    @State private var songMetadataList: [SongMetadata] = []
    

    var body: some View {
        VStack {
            Text("Song Duplicate Deleter")
            TextField("Enter Music Directory Path:", text: $dirPath).padding()
            Button("Browse") {
                showFilePicker()
            }
            .padding()
            Text("Track List:")
            HStack {
                Spacer()
                Text("Title").bold()
                Spacer()
                Text("Artist").bold()
                Spacer()
                Text("Album").bold()
                Spacer()
            }
            List(songMetadataList, id: \.title) { songMetadata in
                            HStack {
                                Text(songMetadata.title)
                                Spacer()
                                Text(songMetadata.artist)
                                Spacer()
                                Text(songMetadata.album)
                            }
                        }
                        .frame(maxHeight: 400)
                        

            Button("Find Duplicate Tracks") {
                findDuplicates()
            }
            .padding()
            
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
    
//    func updateFilesList() {
//            do {
//                let fileManager = FileManager.default
//                let contents = try fileManager.contentsOfDirectory(atPath: dirPath)
//                files = contents
//                
//            } catch {
//                print("Error listing files: \(error.localizedDescription)")
//            }
//        }
    
    func updateMetadataList() {
        do {
            let fileManager  = FileManager.default
            let folderContents = try fileManager.contentsOfDirectory(atPath: dirPath)
            for fileName in folderContents {
                let filePath = URL(fileURLWithPath: dirPath + "/" + fileName)
                let metadata = extractMetadata(from: filePath)
                if let validMetadata = metadata {
                    songMetadataList.append(validMetadata)
                }
                
            }
        }
        catch {
            print("Error listing files: \(error.localizedDescription)")
        }
    }
        
    func extractMetadata(from filePath: URL) -> SongMetadata? {
        do {
            let asset = AVAsset(url: filePath)
            let metadata = asset.metadata
            var title = ""
            var artist = ""
            var album = ""
            
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
            return SongMetadata(title: title, artist: artist, album: album)
            
        }
        catch {
                // Step 7: Handle any errors during metadata extraction
                print("Error extracting metadata: \(error.localizedDescription)")
                return nil
            }
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
