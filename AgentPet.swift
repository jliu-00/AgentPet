import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var fileTimer: Timer?
    var animationTimer: Timer?
    var isWorking = false
    var currentFrame = 0
    enum PetType {
        case cat
        case rat
    }

    
    var currentPet: PetType = .rat
    let statusFilePath = NSHomeDirectory() + "/.agentpet_status"
    
    var catFrames: [NSImage] = []
    var ratFrames: [NSImage] = []
    var mouseRestImage: NSImage?
    var catRestImage: NSImage?
    
    func loadSprite(_ name: String) -> NSImage? {
        // If not bundled correctly, fallback to current directory + path
        var path = Bundle.main.path(forResource: name, ofType: "png")
        if path == nil {
            let directPath = "AgentPet.app/Contents/Resources/\(name).png"
            if FileManager.default.fileExists(atPath: directPath) {
                path = directPath
            }
        }
        
        guard let validPath = path, let img = NSImage(contentsOfFile: validPath) else {
            print("Failed to load \(name).png")
            // Fallback empty image
            let empty = NSImage(size: NSSize(width: 17, height: 17))
            empty.isTemplate = true
            return empty
        }
        
        let aspect = img.size.width / img.size.height
        let newHeight: CGFloat = 17.0
        let newWidth = newHeight * aspect
        img.size = NSSize(width: newWidth, height: newHeight)
        img.isTemplate = true
        return img
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for i in 0...3 {
            if let frame = loadSprite("cat\(i)") { catFrames.append(frame) }
            if let frame = loadSprite("rat\(i)") { ratFrames.append(frame) }
        }
        
        mouseRestImage = loadSprite("ratRest")
        catRestImage = loadSprite("catRest")
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = catFrames.first
        
        let menu = NSMenu()
        let catItem = NSMenuItem(title: "Cat", action: #selector(selectCat), keyEquivalent: "")
        catItem.state = .on
        let mouseItem = NSMenuItem(title: "Rat", action: #selector(selectMouse), keyEquivalent: "")
        
        menu.addItem(catItem)
        menu.addItem(mouseItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        
        fileTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkStatus), userInfo: nil, repeats: true)
        animationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateFrame), userInfo: nil, repeats: true)
    }
    
    @objc func selectCat() {
        currentPet = .cat
        if let menu = statusItem.menu {
            menu.items[0].state = .on
            menu.items[1].state = .off
        }
        updateFrame()
    }
    
    @objc func selectMouse() {
        currentPet = .rat
        if let menu = statusItem.menu {
            menu.items[0].state = .off
            menu.items[1].state = .on
        }
        updateFrame()
    }
    
    var lastTranscriptMtime: Double = 0
    var workingUntil: Date = Date.distantPast
    var cancelledUntil: Date = Date.distantPast
    var lastCancelCount: Int = 0
    var isInitialized: Bool = false
    var isChecking: Bool = false
    var lastCheckTime: Date = Date.distantPast

    func getCancelCount() -> Int {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "timeout 1 grep -c 'executor is not currently running' ~/Library/Logs/Antigravity/language_server.log 2>/dev/null"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            if #available(macOS 10.13, *) { try task.run() } else { task.launch() }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            if let output = String(data: data, encoding: .utf8), let count = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return count
            }
        } catch {}
        return 0
    }

    func getLatestTranscriptState() -> (mtime: Double, isWorking: Bool) {
        let brainDir = NSHomeDirectory() + "/.gemini/antigravity/brain"
        guard let convDirs = try? FileManager.default.contentsOfDirectory(atPath: brainDir) else { return (0, false) }
        
        var latestFile: String?
        var latestMtime: Double = 0
        for conv in convDirs {
            let path = brainDir + "/" + conv + "/.system_generated/logs/transcript.jsonl"
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let modDate = attrs[.modificationDate] as? Date {
                let mtime = modDate.timeIntervalSince1970
                if mtime > latestMtime {
                    latestMtime = mtime
                    latestFile = path
                }
            }
        }
        
        if Date().timeIntervalSince1970 - latestMtime > 300 {
            return (latestMtime, false)
        }
        
        guard let path = latestFile, let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)) else { return (0, false) }
        defer { try? fileHandle.close() }
        
        fileHandle.seekToEndOfFile()
        let fileSize = fileHandle.offsetInFile
        let readOffset = max(0, Int64(fileSize) - 65536)
        fileHandle.seek(toFileOffset: UInt64(readOffset))
        
        let data = fileHandle.readDataToEndOfFile()
        let text = String(decoding: data, as: UTF8.self)
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if let lastLine = lines.last,
           let lineData = lastLine.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
           let type = dict["type"] as? String {
            
            // Agent is idle only when the last entry is a final PLANNER_RESPONSE with no pending tool calls
            if type == "PLANNER_RESPONSE" {
                if dict["tool_calls"] == nil {
                    return (latestMtime, false)
                }
            }
            return (latestMtime, true)
        }
        return (latestMtime, false)
    }

    func performChecksAsync() {
        // Allow fast re-checks: 0.3s interval instead of 1s to catch short-lived sessions
        if Date().timeIntervalSince(lastCheckTime) < 0.3 || isChecking { return }
        isChecking = true
        lastCheckTime = Date()
        
        DispatchQueue.global(qos: .background).async {
            let state = self.getLatestTranscriptState()
            let cancelCount = self.getCancelCount()
            
            DispatchQueue.main.async {
                if !self.isInitialized {
                    self.lastTranscriptMtime = state.mtime
                    self.lastCancelCount = cancelCount
                    self.isInitialized = true
                    self.isChecking = false
                    return
                }
                
                // 1. Cancel detection: suppress working state for 5s after cancel
                if cancelCount > self.lastCancelCount {
                    self.workingUntil = Date.distantPast
                    self.cancelledUntil = Date().addingTimeInterval(5.0)
                    self.lastCancelCount = cancelCount
                    self.isChecking = false
                    return
                }
                self.lastCancelCount = cancelCount
                
                // 2. If recently cancelled, ignore working state until new mtime arrives
                //    that is newer than the cancel moment
                if Date() < self.cancelledUntil {
                    // Only exit cancel suppression if transcript mtime changed
                    // (meaning a new user message was sent after the cancel)
                    if state.mtime > self.lastTranscriptMtime {
                        self.cancelledUntil = Date.distantPast
                    } else {
                        self.isChecking = false
                        return
                    }
                }
                
                // 3. Mtime change = new activity, immediately start running
                if state.mtime > self.lastTranscriptMtime {
                    self.workingUntil = Date().addingTimeInterval(3.0)
                }
                
                // 4. Content-based: if transcript says working, extend the timer
                if state.isWorking {
                    self.workingUntil = Date().addingTimeInterval(3.0)
                }
                
                self.lastTranscriptMtime = state.mtime
                self.isChecking = false
            }
        }
    }

    func isAntigravityWorking() -> Bool {
        performChecksAsync()
        return Date() < workingUntil
    }

    @objc func checkStatus() {
        // 1. Native Antigravity monitoring
        if isAntigravityWorking() {
            isWorking = true
            return
        }
        
        // 2. Fallback to external status file for custom scripts
        do {
            let content = try String(contentsOfFile: statusFilePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            isWorking = (content == "working")
        } catch {
            isWorking = false
        }
    }
    
    @objc func updateFrame() {
        let activeFrames = currentPet == .rat ? ratFrames : catFrames
        if activeFrames.isEmpty { return }
        
        if isWorking {
            currentFrame = (currentFrame + 1) % activeFrames.count
            statusItem.button?.image = activeFrames[currentFrame]
        } else {
            statusItem.button?.image = currentPet == .rat ? (mouseRestImage ?? activeFrames.first) : (catRestImage ?? activeFrames.first)
            currentFrame = 0
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
