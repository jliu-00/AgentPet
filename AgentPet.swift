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
        case fightingRat
        case hulaCat
        case hulaRat
    }

    
    var currentPet: PetType = .fightingRat
    let statusFilePath = NSHomeDirectory() + "/.agentpet_status"
    
    var catFrames: [NSImage] = []
    var ratFrames: [NSImage] = []
    var fightingRatFrames: [NSImage] = []
    var hulaCatFrames: [NSImage] = []
    var hulaRatFrames: [NSImage] = []
    var mouseRestImage: NSImage?
    var catRestImage: NSImage?
    var fightingRatRestImage: NSImage?
    var hulaCatRestImage: NSImage?
    var hulaRatRestImage: NSImage?
    
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
        let newHeight: CGFloat = 22.0
        let newWidth = newHeight * aspect
        img.size = NSSize(width: newWidth, height: newHeight)
        return img
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for i in 0...3 {
            if let frame = loadSprite("cat\(i)") { catFrames.append(frame) }
            if let frame = loadSprite("rat\(i)") { ratFrames.append(frame) }
            if let frame = loadSprite("fightingRat\(i)") { fightingRatFrames.append(frame) }
        }
        for i in 0...13 {
            if let frame = loadSprite("hulaCat\(i)") { hulaCatFrames.append(frame) }
            if let frame = loadSprite("hulaRat\(i)") { hulaRatFrames.append(frame) }
        }
        
        mouseRestImage = loadSprite("ratRest")
        catRestImage = loadSprite("catRest")
        fightingRatRestImage = loadSprite("fightingRatRest")
        hulaCatRestImage = loadSprite("hulaCatRest")
        hulaRatRestImage = loadSprite("hulaRatRest")
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = fightingRatRestImage ?? ratFrames.first
        
        let menu = NSMenu()
        let catItem = NSMenuItem(title: "Cat", action: #selector(selectCat), keyEquivalent: "")
        catItem.state = .off
        let mouseItem = NSMenuItem(title: "Rat", action: #selector(selectMouse), keyEquivalent: "")
        mouseItem.state = .off
        let fightingRatItem = NSMenuItem(title: "Fighting Rat", action: #selector(selectFightingRat), keyEquivalent: "")
        fightingRatItem.state = .on
        let hulaCatItem = NSMenuItem(title: "Hula Cat", action: #selector(selectHulaCat), keyEquivalent: "")
        hulaCatItem.state = .off
        let hulaRatItem = NSMenuItem(title: "Hula Rat", action: #selector(selectHulaRat), keyEquivalent: "")
        hulaRatItem.state = .off
        
        menu.addItem(catItem)
        menu.addItem(mouseItem)
        menu.addItem(fightingRatItem)
        menu.addItem(hulaCatItem)
        menu.addItem(hulaRatItem)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        
        fileTimer = Timer.scheduledTimer(timeInterval: 0.15, target: self, selector: #selector(checkStatus), userInfo: nil, repeats: true)
    }
    
    @objc func selectCat() {
        currentPet = .cat
        if let menu = statusItem.menu {
            menu.items[0].state = .on
            menu.items[1].state = .off
            menu.items[2].state = .off
            menu.items[3].state = .off
            menu.items[4].state = .off
        }
        applyCurrentStateImage()
    }
    
    @objc func selectMouse() {
        currentPet = .rat
        if let menu = statusItem.menu {
            menu.items[0].state = .off
            menu.items[1].state = .on
            menu.items[2].state = .off
            menu.items[3].state = .off
            menu.items[4].state = .off
        }
        applyCurrentStateImage()
    }
    
    @objc func selectFightingRat() {
        currentPet = .fightingRat
        if let menu = statusItem.menu {
            menu.items[0].state = .off
            menu.items[1].state = .off
            menu.items[2].state = .on
            menu.items[3].state = .off
            menu.items[4].state = .off
        }
        applyCurrentStateImage()
    }
    
    @objc func selectHulaCat() {
        currentPet = .hulaCat
        if let menu = statusItem.menu {
            menu.items[0].state = .off
            menu.items[1].state = .off
            menu.items[2].state = .off
            menu.items[3].state = .on
            menu.items[4].state = .off
        }
        applyCurrentStateImage()
    }
    
    @objc func selectHulaRat() {
        currentPet = .hulaRat
        if let menu = statusItem.menu {
            menu.items[0].state = .off
            menu.items[1].state = .off
            menu.items[2].state = .off
            menu.items[3].state = .off
            menu.items[4].state = .on
        }
        applyCurrentStateImage()
    }
    
    func applyCurrentStateImage() {
        if wasWorking {
            animationTimer?.invalidate()
            let interval: TimeInterval = (currentPet == .hulaRat || currentPet == .hulaCat) ? 0.15 : 0.1
            animationTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateFrame), userInfo: nil, repeats: true)
            updateFrame()
        } else {
            let activeFrames: [NSImage]
            let restImage: NSImage?
            switch currentPet {
            case .rat:
                activeFrames = ratFrames
                restImage = mouseRestImage
            case .cat:
                activeFrames = catFrames
                restImage = catRestImage
            case .fightingRat:
                activeFrames = fightingRatFrames
                restImage = fightingRatRestImage
            case .hulaCat:
                activeFrames = hulaCatFrames
                restImage = hulaCatRestImage
            case .hulaRat:
                activeFrames = hulaRatFrames
                restImage = hulaRatRestImage
            }
            statusItem.button?.image = restImage ?? activeFrames.first
            currentFrame = 0
        }
    }
    
    var lastTranscriptMtime: Double = 0
    var workingUntil: Date = Date.distantPast
    var cancelledUntil: Date = Date.distantPast
    var lastCancelCount: Int = 0
    var lastCancelLogMtime: Double = 0
    var isInitialized: Bool = false
    var isChecking: Bool = false
    var lastCheckTime: Date = Date.distantPast
    var wasWorking: Bool = false

    let cancelLogPath = NSHomeDirectory() + "/Library/Logs/Antigravity/language_server.log"

    func getCancelCount() -> Int {
        // Only re-read log file when its mtime changes
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: cancelLogPath),
              let modDate = attrs[.modificationDate] as? Date else { return lastCancelCount }
        let mtime = modDate.timeIntervalSince1970
        if mtime == lastCancelLogMtime { return lastCancelCount }
        lastCancelLogMtime = mtime

        guard let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: cancelLogPath)) else { return 0 }
        defer { try? fileHandle.close() }
        fileHandle.seekToEndOfFile()
        let fileSize = fileHandle.offsetInFile
        let readOffset = max(0, Int64(fileSize) - 65536)
        fileHandle.seek(toFileOffset: UInt64(readOffset))
        let data = fileHandle.readDataToEndOfFile()
        let text = String(decoding: data, as: UTF8.self)
        let pattern = "executor is not currently running"
        var count = 0
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: pattern, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }
        return count
    }

    func getLatestTranscriptMtime() -> Double {
        let brainDir = NSHomeDirectory() + "/.gemini/antigravity/brain"
        guard let convDirs = try? FileManager.default.contentsOfDirectory(atPath: brainDir) else { return 0 }
        
        var latestMtime: Double = 0
        for conv in convDirs {
            let path = brainDir + "/" + conv + "/.system_generated/logs/transcript.jsonl"
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let modDate = attrs[.modificationDate] as? Date {
                let mtime = modDate.timeIntervalSince1970
                if mtime > latestMtime {
                    latestMtime = mtime
                }
            }
        }
        return latestMtime
    }

    func readTranscriptContent() -> Bool {
        let brainDir = NSHomeDirectory() + "/.gemini/antigravity/brain"
        guard let convDirs = try? FileManager.default.contentsOfDirectory(atPath: brainDir) else { return false }
        
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
            return false
        }
        
        guard let path = latestFile, let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)) else { return false }
        defer { try? fileHandle.close() }
        
        fileHandle.seekToEndOfFile()
        let fileSize = fileHandle.offsetInFile
        let readOffset = max(0, Int64(fileSize) - 65536)
        fileHandle.seek(toFileOffset: UInt64(readOffset))
        
        let data = fileHandle.readDataToEndOfFile()
        let text = String(decoding: data, as: UTF8.self)
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if let lastLine = lines.last,
           let lineData = lastLine.data(using: .utf8) {
            
            guard let dict = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let type = dict["type"] as? String else {
                // Parse failed (e.g. mid-write), assume working to retry next cycle
                return true
            }
            
            // Agent is idle only when the last entry is a final PLANNER_RESPONSE with no pending tool calls
            if type == "PLANNER_RESPONSE" {
                if dict["tool_calls"] == nil {
                    return false
                }
            }
            return true
        }
        return false
    }

    func performChecksAsync() {
        if Date().timeIntervalSince(lastCheckTime) < 0.1 || isChecking { return }
        isChecking = true
        lastCheckTime = Date()
        
        DispatchQueue.global(qos: .background).async {
            // Cheap: stat() only to get mtime
            let mtime = self.getLatestTranscriptMtime()
            let mtimeChanged = mtime > self.lastTranscriptMtime

            // Expensive content read only when mtime changed, currently working, or not initialized
            let contentIsWorking: Bool
            if mtimeChanged || self.wasWorking || !self.isInitialized {
                contentIsWorking = self.readTranscriptContent()
            } else {
                contentIsWorking = false
            }

            // Cancel count: only re-reads log when its own mtime changes
            let cancelCount = self.getCancelCount()
            
            DispatchQueue.main.async {
                if !self.isInitialized {
                    self.lastTranscriptMtime = mtime
                    self.lastCancelCount = cancelCount
                    self.isInitialized = true
                    if contentIsWorking {
                        self.workingUntil = Date().addingTimeInterval(5.0)
                    }
                    self.isChecking = false
                    self.applyWorkingState(contentIsWorking)
                    return
                }
                
                // 1. Cancel detection: suppress working state for 5s after cancel
                if cancelCount > self.lastCancelCount {
                    self.workingUntil = Date.distantPast
                    self.cancelledUntil = Date().addingTimeInterval(5.0)
                    self.lastCancelCount = cancelCount
                    self.lastTranscriptMtime = mtime
                    self.isChecking = false
                    self.applyWorkingState(false)
                    return
                }
                self.lastCancelCount = cancelCount
                
                // 2. If recently cancelled, ignore working state until new mtime arrives
                if Date() < self.cancelledUntil {
                    if mtimeChanged {
                        self.cancelledUntil = Date.distantPast
                    } else {
                        self.lastTranscriptMtime = mtime
                        self.isChecking = false
                        return
                    }
                }
                
                // 3. Mtime change = new activity, immediately start running
                if mtimeChanged {
                    self.workingUntil = Date().addingTimeInterval(5.0)
                }
                
                // 4. Content-based: if transcript says working, extend the timer
                if contentIsWorking {
                    self.workingUntil = Date().addingTimeInterval(5.0)
                }
                
                self.lastTranscriptMtime = mtime
                self.isChecking = false
                
                // Apply state immediately instead of waiting for next checkStatus cycle
                self.applyWorkingState(Date() < self.workingUntil)
            }
        }
    }

    func applyWorkingState(_ nowWorking: Bool) {
        if nowWorking && !wasWorking {
            if animationTimer == nil {
                let interval: TimeInterval = (currentPet == .hulaRat || currentPet == .hulaCat) ? 0.15 : 0.1
                animationTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateFrame), userInfo: nil, repeats: true)
            }
        } else if !nowWorking && wasWorking {
            let activeFrames: [NSImage]
            let restImage: NSImage?
            switch currentPet {
            case .rat:
                activeFrames = ratFrames
                restImage = mouseRestImage
            case .cat:
                activeFrames = catFrames
                restImage = catRestImage
            case .fightingRat:
                activeFrames = fightingRatFrames
                restImage = fightingRatRestImage
            case .hulaCat:
                activeFrames = hulaCatFrames
                restImage = hulaCatRestImage
            case .hulaRat:
                activeFrames = hulaRatFrames
                restImage = hulaRatRestImage
            }
            statusItem.button?.image = restImage ?? activeFrames.first
            currentFrame = 0
            animationTimer?.invalidate()
            animationTimer = nil
        }
        isWorking = nowWorking
        wasWorking = nowWorking
    }

    @objc func checkStatus() {
        performChecksAsync()
        let nowWorking: Bool
        if Date() < workingUntil {
            nowWorking = true
        } else if let content = try? String(contentsOfFile: statusFilePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
            nowWorking = (content == "working")
        } else {
            nowWorking = false
        }
        applyWorkingState(nowWorking)
    }
    
    @objc func updateFrame() {
        let activeFrames: [NSImage]
        switch currentPet {
        case .rat: activeFrames = ratFrames
        case .cat: activeFrames = catFrames
        case .fightingRat: activeFrames = fightingRatFrames
        case .hulaCat: activeFrames = hulaCatFrames
        case .hulaRat: activeFrames = hulaRatFrames
        }
        if activeFrames.isEmpty { return }
        currentFrame = (currentFrame + 1) % activeFrames.count
        statusItem.button?.image = activeFrames[currentFrame]
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
