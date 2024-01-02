import SwiftUI
import AppKit

struct ContentView: View {
    @State private var dirPath: String = ""
    @State private var deleteConfimed: Bool = false
    @State private var duplicates: [String] = []
    @State private var files: [String] = []

    var body: some View {
        VStack {
            Text("Song Duplicate Deleter")
            TextField("Enter Music Directory Path:", text: $dirPath).padding()
            Button("Browse") {
                showFilePicker()
            }
            .padding()
            Text("Track List:")
            List(files, id: \.self) { file in
                            Text(file)
                        }
                        .frame(maxHeight: 400)
                        .padding()

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
                        updateFilesList()
                    }
                }
            }
        }
    }
    
    func updateFilesList() {
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: dirPath)
                files = contents
                
            } catch {
                print("Error listing files: \(error.localizedDescription)")
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
