import Cocoa
import Foundation
import AVFoundation

// MARK: - 3D Engine Structures & Math

public struct Vector3 {
    public var x: Float = 0
    public var y: Float = 0
    public var z: Float = 0
    
    public init(x: Float = 0, y: Float = 0, z: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public class Matrix4x4 {
    public var m: [[Float]] = Array(repeating: Array(repeating: 0.0, count: 4), count: 4)
    
    public init() {}
    
    public static func identity() -> Matrix4x4 {
        let mat = Matrix4x4()
        mat.m[0][0] = 1.0; mat.m[1][1] = 1.0; mat.m[2][2] = 1.0; mat.m[3][3] = 1.0
        return mat
    }
    
    public static func projection(fov: Float, aspect: Float, zNear: Float, zFar: Float) -> Matrix4x4 {
        let fovRad: Float = 1.0 / tan(fov * 0.5 / 180.0 * .pi)
        let mat = Matrix4x4()
        mat.m[0][0] = aspect * fovRad
        mat.m[1][1] = fovRad
        mat.m[2][2] = zFar / (zFar - zNear)
        mat.m[3][2] = (-zFar * zNear) / (zFar - zNear)
        mat.m[2][3] = 1.0
        mat.m[3][3] = 0.0
        return mat
    }
    
    public static func rotationX(angle: Float) -> Matrix4x4 {
        let mat = Matrix4x4()
        mat.m[0][0] = 1
        mat.m[1][1] = cos(angle)
        mat.m[1][2] = sin(angle)
        mat.m[2][1] = -sin(angle)
        mat.m[2][2] = cos(angle)
        mat.m[3][3] = 1
        return mat
    }
    
    public static func rotationY(angle: Float) -> Matrix4x4 {
        let mat = Matrix4x4()
        mat.m[0][0] = cos(angle)
        mat.m[0][2] = sin(angle)
        mat.m[1][1] = 1
        mat.m[2][0] = -sin(angle)
        mat.m[2][2] = cos(angle)
        mat.m[3][3] = 1
        return mat
    }
    
    public static func rotationZ(angle: Float) -> Matrix4x4 {
        let mat = Matrix4x4()
        mat.m[0][0] = cos(angle)
        mat.m[0][1] = sin(angle)
        mat.m[1][0] = -sin(angle)
        mat.m[1][1] = cos(angle)
        mat.m[2][2] = 1
        mat.m[3][3] = 1
        return mat
    }
    
    public static func multiplyVector(_ i: Vector3, _ m: Matrix4x4) -> Vector3 {
        var v = Vector3()
        v.x = i.x * m.m[0][0] + i.y * m.m[1][0] + i.z * m.m[2][0] + m.m[3][0]
        v.y = i.x * m.m[0][1] + i.y * m.m[1][1] + i.z * m.m[2][1] + m.m[3][1]
        v.z = i.x * m.m[0][2] + i.y * m.m[1][2] + i.z * m.m[2][2] + m.m[3][2]
        let w = i.x * m.m[0][3] + i.y * m.m[1][3] + i.z * m.m[2][3] + m.m[3][3]
        if w != 0.0 {
            v.x /= w; v.y /= w; v.z /= w
        }
        return v
    }
}

public class Triangle {
    public var p: [Vector3] = [Vector3(), Vector3(), Vector3()]
    public var color: NSColor = .white
    
    public init() {}
    public init(p: [Vector3], color: NSColor = .white) {
        self.p = p
        self.color = color
    }
}

public class Mesh3D {
    public var id: String = ""
    public var tris: [Triangle] = []
    public var rotX: Float = 0, rotY: Float = 0, rotZ: Float = 0
    public var posX: Float = 0, posY: Float = 0, posZ: Float = 0
    public var scaleX: Float = 1.0, scaleY: Float = 1.0, scaleZ: Float = 1.0
    public var visible: Bool = true
    
    public init(id: String = "") {
        self.id = id
    }
    
    public static func createCube(id: String, size: Float, color: NSColor) -> Mesh3D {
        let mesh = Mesh3D(id: id)
        let s = size / 2.0
        let v = [
            Vector3(x: -s, y: -s, z: -s), Vector3(x: -s, y: s, z: -s),
            Vector3(x: s, y: s, z: -s), Vector3(x: s, y: -s, z: -s),
            Vector3(x: -s, y: -s, z: s), Vector3(x: -s, y: s, z: s),
            Vector3(x: s, y: s, z: s), Vector3(x: s, y: -s, z: s)
        ]
        let indices = [
            [0,1,2], [0,2,3], [4,0,3], [4,3,7], [5,4,7], [5,7,6],
            [1,5,6], [1,6,2], [4,5,1], [4,1,0], [3,2,6], [3,6,7]
        ]
        for idx in indices {
            mesh.tris.append(Triangle(p: [v[idx[0]], v[idx[1]], v[idx[2]]], color: color))
        }
        return mesh
    }
    
    public static func createPyramid(id: String, size: Float, color: NSColor) -> Mesh3D {
        let mesh = Mesh3D(id: id)
        let s = size / 2.0
        let v = [
            Vector3(x: 0, y: s, z: 0),
            Vector3(x: -s, y: -s, z: -s), Vector3(x: s, y: -s, z: -s),
            Vector3(x: s, y: -s, z: s), Vector3(x: -s, y: -s, z: s)
        ]
        let indices = [
            [1,2,4], [2,3,4], [0,2,1], [0,3,2], [0,4,3], [0,1,4]
        ]
        for idx in indices {
            mesh.tris.append(Triangle(p: [v[idx[0]], v[idx[1]], v[idx[2]]], color: color))
        }
        return mesh
    }
    
    public static func createPlane(id: String, size: Float, color: NSColor) -> Mesh3D {
        let mesh = Mesh3D(id: id)
        let s = size / 2.0
        let v = [
            Vector3(x: -s, y: 0, z: -s), Vector3(x: s, y: 0, z: -s),
            Vector3(x: -s, y: 0, z: s), Vector3(x: s, y: 0, z: s)
        ]
        for idx in [[0,1,2], [1,3,2]] {
            mesh.tris.append(Triangle(p: [v[idx[0]], v[idx[1]], v[idx[2]]], color: color))
        }
        return mesh
    }
    
    public static func createSphere(id: String, radius: Float, rings: Int, sectors: Int, color: NSColor) -> Mesh3D {
        let mesh = Mesh3D(id: id)
        let constR = 1.0 / Float(rings - 1)
        let constS = 1.0 / Float(sectors - 1)
        let pi = Float.pi
        let pi2 = Float.pi / 2.0
        
        var verts: [Vector3] = []
        for r in 0..<rings {
            for s in 0..<sectors {
                let y = sin(-pi2 + pi * Float(r) * constR)
                let x = cos(2 * pi * Float(s) * constS) * sin(pi * Float(r) * constR)
                let z = sin(2 * pi * Float(s) * constS) * sin(pi * Float(r) * constR)
                verts.append(Vector3(x: x * radius, y: y * radius, z: z * radius))
            }
        }
        
        for r in 0..<(rings - 1) {
            for s in 0..<(sectors - 1) {
                let i0 = r * sectors + s
                let i1 = r * sectors + (s + 1)
                let i2 = (r + 1) * sectors + (s + 1)
                let i3 = (r + 1) * sectors + s
                mesh.tris.append(Triangle(p: [verts[i0], verts[i1], verts[i2]], color: color))
                mesh.tris.append(Triangle(p: [verts[i0], verts[i2], verts[i3]], color: color))
            }
        }
        return mesh
    }
    
    public static func loadOBJ(id: String, filepath: String, color: NSColor) -> Mesh3D {
        let mesh = Mesh3D(id: id)
        var verts: [Vector3] = []
        
        guard let content = try? String(contentsOfFile: filepath, encoding: .utf8) else {
            return mesh
        }
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.isEmpty { continue }
            
            if parts[0] == "v" && parts.count >= 4 {
                if let x = Float(parts[1]), let y = Float(parts[2]), let z = Float(parts[3]) {
                    verts.append(Vector3(x: x, y: y, z: z))
                }
            } else if parts[0] == "f" && parts.count >= 4 {
                let parseIdx = { (str: String) -> Int? in
                    let first = str.components(separatedBy: "/")[0]
                    if let val = Int(first) { return val - 1 }
                    return nil
                }
                
                if let i1 = parseIdx(parts[1]), let i2 = parseIdx(parts[2]), let i3 = parseIdx(parts[3]),
                   i1 < verts.count && i2 < verts.count && i3 < verts.count {
                    mesh.tris.append(Triangle(p: [verts[i1], verts[i2], verts[i3]], color: color))
                    if parts.count == 5, let i4 = parseIdx(parts[4]), i4 < verts.count {
                        mesh.tris.append(Triangle(p: [verts[i1], verts[i3], verts[i4]], color: color))
                    }
                }
            }
        }
        return mesh
    }
}

// MARK: - 3D Renderer Pipeline

public class WinterRenderer3D {
    private var matProj = Matrix4x4()
    public var meshes: [Mesh3D] = []
    public var cameraPos = Vector3(x: 0, y: 0, z: 0)
    public var lightDir = Vector3(x: 0, y: -1, z: -1)
    public var ambientColor = NSColor(red: 40/255.0, green: 40/255.0, blue: 40/255.0, alpha: 1.0)
    
    public init() {}
    
    public func initRenderer(width: Int, height: Int) {
        meshes.removeAll()
        let aspect = Float(height) / Float(width)
        matProj = Matrix4x4.projection(fov: 90.0, aspect: aspect, zNear: 0.1, zFar: 1000.0)
        
        let l = sqrt(lightDir.x * lightDir.x + lightDir.y * lightDir.y + lightDir.z * lightDir.z)
        lightDir.x /= l; lightDir.y /= l; lightDir.z /= l
    }
    
    public func render(context: CGContext, width: CGFloat, height: CGFloat) {
        var trianglesToRaster: [Triangle] = []
        
        for mesh in meshes {
            if !mesh.visible { continue }
            
            let matRotZ = Matrix4x4.rotationZ(angle: mesh.rotZ)
            let matRotX = Matrix4x4.rotationX(angle: mesh.rotX)
            let matRotY = Matrix4x4.rotationY(angle: mesh.rotY)
            
            for tri in mesh.tris {
                let triTrans = Triangle()
                for i in 0..<3 {
                    let scaled = Vector3(x: tri.p[i].x * mesh.scaleX, y: tri.p[i].y * mesh.scaleY, z: tri.p[i].z * mesh.scaleZ)
                    let r1 = Matrix4x4.multiplyVector(scaled, matRotZ)
                    let r2 = Matrix4x4.multiplyVector(r1, matRotX)
                    let r3 = Matrix4x4.multiplyVector(r2, matRotY)
                    
                    triTrans.p[i] = Vector3(x: r3.x + mesh.posX, y: r3.y + mesh.posY, z: r3.z + mesh.posZ)
                }
                
                let l1 = Vector3(x: triTrans.p[1].x - triTrans.p[0].x, y: triTrans.p[1].y - triTrans.p[0].y, z: triTrans.p[1].z - triTrans.p[0].z)
                let l2 = Vector3(x: triTrans.p[2].x - triTrans.p[0].x, y: triTrans.p[2].y - triTrans.p[0].y, z: triTrans.p[2].z - triTrans.p[0].z)
                
                var normal = Vector3(
                    x: l1.y * l2.z - l1.z * l2.y,
                    y: l1.z * l2.x - l1.x * l2.z,
                    z: l1.x * l2.y - l1.y * l2.x
                )
                let normalLen = sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z)
                if normalLen == 0 { continue }
                normal.x /= normalLen; normal.y /= normalLen; normal.z /= normalLen
                
                let camRay = Vector3(x: triTrans.p[0].x - cameraPos.x, y: triTrans.p[0].y - cameraPos.y, z: triTrans.p[0].z - cameraPos.z)
                
                if (normal.x * camRay.x + normal.y * camRay.y + normal.z * camRay.z) < 0 {
                    let dp = max(0.1, normal.x * lightDir.x + normal.y * lightDir.y + normal.z * lightDir.z)
                    
                    let triColor = tri.color.usingColorSpace(.sRGB) ?? tri.color
                    let r = min(1.0, Float(triColor.redComponent) * dp + Float(ambientColor.redComponent))
                    let g = min(1.0, Float(triColor.greenComponent) * dp + Float(ambientColor.greenComponent))
                    let b = min(1.0, Float(triColor.blueComponent) * dp + Float(ambientColor.blueComponent))
                    
                    triTrans.color = NSColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
                    
                    let triProj = Triangle(p: [Vector3(), Vector3(), Vector3()], color: triTrans.color)
                    for i in 0..<3 {
                        let viewPt = Vector3(x: triTrans.p[i].x - cameraPos.x, y: triTrans.p[i].y - cameraPos.y, z: triTrans.p[i].z - cameraPos.z)
                        var projPt = Matrix4x4.multiplyVector(viewPt, matProj)
                        
                        projPt.x = (projPt.x + 1.0) * 0.5 * Float(width)
                        projPt.y = (projPt.y + 1.0) * 0.5 * Float(height)
                        triProj.p[i] = projPt
                    }
                    trianglesToRaster.append(triProj)
                }
            }
        }
        
        // Painter's algorithm
        trianglesToRaster.sort { t1, t2 in
            let z1 = (t1.p[0].z + t1.p[1].z + t1.p[2].z) / 3.0
            let z2 = (t2.p[0].z + t2.p[1].z + t2.p[2].z) / 3.0
            return z1 > z2
        }
        
        context.setStrokeColor(NSColor(white: 0, alpha: 0.08).cgColor)
        context.setLineWidth(1.0)
        
        for tri in trianglesToRaster {
            context.beginPath()
            context.move(to: CGPoint(x: CGFloat(tri.p[0].x), y: CGFloat(tri.p[0].y)))
            context.addLine(to: CGPoint(x: CGFloat(tri.p[1].x), y: CGFloat(tri.p[1].y)))
            context.addLine(to: CGPoint(x: CGFloat(tri.p[2].x), y: CGFloat(tri.p[2].y)))
            context.closePath()
            
            context.setFillColor(tri.color.cgColor)
            context.fillPath()
            
            context.beginPath()
            context.move(to: CGPoint(x: CGFloat(tri.p[0].x), y: CGFloat(tri.p[0].y)))
            context.addLine(to: CGPoint(x: CGFloat(tri.p[1].x), y: CGFloat(tri.p[1].y)))
            context.addLine(to: CGPoint(x: CGFloat(tri.p[2].x), y: CGFloat(tri.p[2].y)))
            context.closePath()
            context.strokePath()
        }
    }
}

// MARK: - Audio Engine

public class WinterAudio {
    private var loadedTracks: [String: AVAudioPlayer] = [:]
    
    public init() {}
    
    public func loadAudio(alias: String, pathOrUrl: String) throws {
        var finalURL: URL
        
        if pathOrUrl.lowercased().hasPrefix("http://") || pathOrUrl.lowercased().hasPrefix("https://") {
            guard let url = URL(string: pathOrUrl) else {
                throw NSError(domain: "WinterAudio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL string"])
            }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("winter_audio_\(alias).mp3")
            do {
                let data = try Data(contentsOf: url)
                try data.write(to: tempURL)
                finalURL = tempURL
            } catch {
                throw NSError(domain: "WinterAudio", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to download audio: \(error.localizedDescription)"])
            }
        } else {
            finalURL = URL(fileURLWithPath: pathOrUrl)
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: finalURL)
            player.prepareToPlay()
            loadedTracks[alias] = player
        } catch {
            throw NSError(domain: "WinterAudio", code: 3, userInfo: [NSLocalizedDescriptionKey: "Audio load failed: \(error.localizedDescription)"])
        }
    }
    
    public func playAudio(alias: String, startSeconds: Double = 0) {
        guard let player = loadedTracks[alias] else { return }
        player.currentTime = startSeconds
        player.play()
    }
    
    public func pauseAudio(alias: String) {
        loadedTracks[alias]?.pause()
    }
    
    public func stopAudio(alias: String) {
        loadedTracks[alias]?.stop()
        loadedTracks[alias]?.currentTime = 0
    }
    
    public func setVolume(alias: String, volume: Int) {
        let volFloat = Float(max(0, min(100, volume))) / 100.0
        loadedTracks[alias]?.volume = volFloat
    }
    
    public func stopAll() {
        for player in loadedTracks.values {
            player.stop()
        }
        loadedTracks.removeAll()
    }
}

// MARK: - Engine Viewport & Window

public class ViewportView: NSView {
    public var currentImage: NSImage?
    public weak var engineWindow: WinterEngineWindow?
    
    override public var acceptsFirstResponder: Bool { return true }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.setFill()
        dirtyRect.fill()
        currentImage?.draw(in: bounds)
    }
    
    override public func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        engineWindow?.mouseX = Int(location.x)
        engineWindow?.mouseY = Int(bounds.height - location.y)
    }
    
    override public func mouseDragged(with event: NSEvent) {
        mouseMoved(with: event)
    }
    
    override public func mouseDown(with event: NSEvent) {
        engineWindow?.mousePressed = true
        mouseMoved(with: event)
    }
    
    override public func mouseUp(with event: NSEvent) {
        engineWindow?.mousePressed = false
    }
}

public class WinterEngineWindow: NSWindow {
    public var viewport: ViewportView
    public var keyStates: [String: Bool] = [:]
    public var mouseX: Int = 0
    public var mouseY: Int = 0
    public var mousePressed: Bool = false
    
    public init() {
        let contentRect = NSRect(x: 0, y: 0, width: 800, height: 600)
        self.viewport = ViewportView(frame: contentRect)
        
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "WinterCode Engine Window"
        self.backgroundColor = .black
        self.center()
        
        viewport.autoresizingMask = [.width, .height]
        viewport.engineWindow = self
        self.contentView?.addSubview(viewport)
        self.makeFirstResponder(viewport)
    }
    
    override public func keyDown(with event: NSEvent) {
        if let chars = event.charactersIgnoringModifiers?.uppercased() {
            keyStates[chars] = true
        }
    }
    
    override public func keyUp(with event: NSEvent) {
        if let chars = event.charactersIgnoringModifiers?.uppercased() {
            keyStates[chars] = false
        }
    }
}

// MARK: - WinterCode Interpreter

public class WinterInterpreter {
    private weak var mainForm: WinterIDE?
    private weak var console: NSTextView?
    public var engineWindow: WinterEngineWindow?
    
    private var renderImage: NSImage?
    private var renderContext: CGContext?
    
    private var vars: [String: Double] = [:]
    private var stringVars: [String: String] = [:]
    private var arrayVars: [String: [Double]] = [:]
    private var subroutines: [String: Int] = [:]
    
    private var audioEngine = WinterAudio()
    private var renderer3D = WinterRenderer3D()
    
    private var isRunning: Bool = false
    
    public init(form: WinterIDE, console: NSTextView) {
        self.mainForm = form
        self.console = console
    }
    
    public func setOutputWindow(_ win: WinterEngineWindow) {
        self.engineWindow = win
        let w = Int(win.viewport.bounds.width)
        let h = Int(win.viewport.bounds.height)
        initGraphics(w: w > 0 ? w : 800, h: h > 0 ? h : 600)
    }
    
    private func initGraphics(w: Int, h: Int) {
        guard w > 0 && h > 0 else { return }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        renderContext = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: colorSpace, bitmapInfo: bitmapInfo)
        
        renderContext?.setFillColor(NSColor.black.cgColor)
        renderContext?.fill(CGRect(x: 0, y: 0, width: w, height: h))
        renderer3D.initRenderer(width: w, height: h)
        
        updateViewport()
    }
    
    public func log(_ msg: String, color: NSColor = .lightGray) {
        DispatchQueue.main.async { [weak self] in
            guard let console = self?.console else { return }
            let attrString = NSAttributedString(
                string: msg + "\n",
                attributes: [.foregroundColor: color, .font: NSFont(name: "Menlo", size: 12) ?? NSFont.userFixedPitchFont(ofSize: 12)!]
            )
            console.textStorage?.append(attrString)
            console.scrollToEndOfDocument(nil)
        }
    }
    
    public func stop() {
        isRunning = false
        audioEngine.stopAll()
    }
    
    public func run(code: String) {
        isRunning = true
        vars.removeAll()
        stringVars.removeAll()
        arrayVars.removeAll()
        subroutines.removeAll()
        renderer3D.meshes.removeAll()
        
        let lines = code.components(separatedBy: .newlines)
        var pc = 0
        
        var whileStack: [Int] = []
        var callStack: [Int] = []
        
        // Pre-pass: subroutines
        for (i, rawLine) in lines.enumerated() {
            let tLine = rawLine.trimmingCharacters(in: .whitespaces)
            if tLine.hasPrefix("sub ") {
                let parts = tLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if parts.count > 1 {
                    subroutines[parts[1]] = i
                }
            }
        }
        
        log(">>> Executing...", color: .green)
        
        while pc < lines.count && isRunning {
            let line = lines[pc].trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("//") {
                pc += 1
                continue
            }
            
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            let cmd = parts[0].lowercased()
            
            do {
                switch cmd {
                case "end":
                    isRunning = false
                    
                case "message", "echo":
                    if parts.count > 1 {
                        log(parts[1...].joined(separator: " "))
                    }
                    
                case "window":
                    if parts.count > 2, let engineWin = engineWindow {
                        if parts[1] == "title" {
                            let titleStr = parts[2...].joined(separator: " ")
                            DispatchQueue.main.async { engineWin.title = titleStr }
                        } else if parts[1] == "size", parts.count >= 4 {
                            let w = CGFloat(getVal(parts[2]))
                            let h = CGFloat(getVal(parts[3]))
                            DispatchQueue.main.async { engineWin.setContentSize(NSSize(width: w, height: h)) }
                        }
                    }
                    
                case "set":
                    if parts.count > 3 && parts[2] == "=" {
                        vars[parts[1]] = getVal(parts[3])
                    } else if parts.count > 2 {
                        vars[parts[1]] = getVal(parts[2])
                    }
                    
                case "add":
                    if parts.count > 2 { vars[parts[1]] = (vars[parts[1]] ?? 0) + getVal(parts[2]) }
                    
                case "sub":
                    if parts.count > 2 { vars[parts[1]] = (vars[parts[1]] ?? 0) - getVal(parts[2]) }
                    
                case "mul":
                    if parts.count > 2 { vars[parts[1]] = (vars[parts[1]] ?? 0) * getVal(parts[2]) }
                    
                case "div":
                    if parts.count > 2 { vars[parts[1]] = (vars[parts[1]] ?? 0) / getVal(parts[2]) }
                    
                case "if":
                    if parts.count >= 4 {
                        let left = getVal(parts[1]), right = getVal(parts[3])
                        let op = parts[2]
                        var cond = false
                        if op == "==" { cond = left == right }
                        else if op == ">" { cond = left > right }
                        else if op == "<" { cond = left < right }
                        else if op == ">=" { cond = left >= right }
                        else if op == "<=" { cond = left <= right }
                        else if op == "!=" { cond = left != right }
                        
                        if !cond {
                            var nestCount = 0
                            while pc < lines.count {
                                pc += 1
                                if pc >= lines.count { break }
                                let fw = lines[pc].trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)[0].lowercased()
                                if fw == "if" { nestCount += 1 }
                                else if fw == "endif" && nestCount == 0 { break }
                                else if fw == "else" && nestCount == 0 { break }
                                else if fw == "endif" && nestCount > 0 { nestCount -= 1 }
                            }
                        }
                    }
                    
                case "else":
                    var nestCountElse = 0
                    while pc < lines.count {
                        pc += 1
                        if pc >= lines.count { break }
                        let fw = lines[pc].trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)[0].lowercased()
                        if fw == "if" { nestCountElse += 1 }
                        else if fw == "endif" && nestCountElse == 0 { break }
                        else if fw == "endif" && nestCountElse > 0 { nestCountElse -= 1 }
                    }
                    
                case "endif":
                    break
                    
                case "while":
                    if parts.count >= 4 {
                        let wL = getVal(parts[1]), wR = getVal(parts[3])
                        let wOp = parts[2]
                        var wCond = false
                        if wOp == "==" { wCond = wL == wR }
                        else if wOp == ">" { wCond = wL > wR }
                        else if wOp == "<" { wCond = wL < wR }
                        else if wOp == ">=" { wCond = wL >= wR }
                        else if wOp == "<=" { wCond = wL <= wR }
                        else if wOp == "!=" { wCond = wL != wR }
                        
                        if wCond {
                            if !whileStack.contains(pc) { whileStack.append(pc) }
                        } else {
                            var wNestCount = 0
                            while pc < lines.count {
                                pc += 1
                                if pc >= lines.count { break }
                                let fw = lines[pc].trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)[0].lowercased()
                                if fw == "while" { wNestCount += 1 }
                                else if fw == "endwhile" && wNestCount == 0 { break }
                                else if fw == "endwhile" && wNestCount > 0 { wNestCount -= 1 }
                            }
                            if let last = whileStack.last, last == pc { _ = whileStack.popLast() }
                        }
                    }
                    
                case "endwhile":
                    if let top = whileStack.last { pc = top - 1 }
                    
                case "call":
                    if parts.count > 1, let subLine = subroutines[parts[1]] {
                        callStack.append(pc)
                        pc = subLine
                    } else if parts.count > 1 {
                        log("Runtime Error: Subroutine \(parts[1]) not found", color: .red)
                    }
                    
                case "endsub":
                    if let returnLine = callStack.popLast() { pc = returnLine }
                    
                case "sleep":
                    if parts.count > 1 {
                        let ms = getVal(parts[1])
                        Thread.sleep(forTimeInterval: ms / 1000.0)
                    }
                    
                case "array":
                    if parts.count > 2 && parts[1] == "create" {
                        arrayVars[parts[2]] = []
                    } else if parts.count > 3 && parts[1] == "push" {
                        arrayVars[parts[2]]?.append(getVal(parts[3]))
                    } else if parts.count > 4 && parts[1] == "get" {
                        let idx = Int(getVal(parts[4]))
                        if let arr = arrayVars[parts[3]], idx >= 0 && idx < arr.count {
                            vars[parts[2]] = arr[idx]
                        }
                    } else if parts.count > 4 && parts[1] == "set" {
                        let idx = Int(getVal(parts[4]))
                        if var arr = arrayVars[parts[3]], idx >= 0 && idx < arr.count {
                            arr[idx] = getVal(parts[2])
                            arrayVars[parts[3]] = arr
                        }
                    } else if parts.count > 3 && parts[1] == "length" {
                        vars[parts[2]] = Double(arrayVars[parts[3]]?.count ?? 0)
                    }
                    
                case "math":
                    if parts.count > 3 {
                        let arg = getVal(parts[3])
                        if parts[1] == "sin" { vars[parts[2]] = sin(arg) }
                        else if parts[1] == "cos" { vars[parts[2]] = cos(arg) }
                        else if parts[1] == "tan" { vars[parts[2]] = tan(arg) }
                        else if parts[1] == "sqrt" { vars[parts[2]] = sqrt(arg) }
                        else if parts[1] == "abs" { vars[parts[2]] = abs(arg) }
                        else if parts[1] == "rnd", parts.count > 4 {
                            let minV = Int(getVal(parts[3])), maxV = Int(getVal(parts[4]))
                            vars[parts[2]] = Double(Int.random(in: minV...max(minV, maxV)))
                        }
                    }
                    
                case "file":
                    if parts.count > 3 {
                        let path = parts[2]
                        let valStr = vars[parts[3]] != nil ? String(vars[parts[3]]!) : (stringVars[parts[3]] ?? parts[3])
                        if parts[1] == "write" {
                            try? valStr.write(toFile: path, atomically: true, encoding: .utf8)
                        } else if parts[1] == "append" {
                            if let handle = FileHandle(forWritingAtPath: path) {
                                handle.seekToEndOfFile()
                                if let data = valStr.data(using: .utf8) { handle.write(data) }
                                handle.closeFile()
                            } else {
                                try? valStr.write(toFile: path, atomically: true, encoding: .utf8)
                            }
                        } else if parts[1] == "read" {
                            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                                stringVars[parts[2]] = content
                            }
                        }
                    }
                    
                case "input":
                    if let engineWin = engineWindow, parts.count > 2 {
                        if parts[1] == "key" && parts.count > 3 {
                            let keyName = parts[2].uppercased()
                            vars[parts[3]] = (engineWin.keyStates[keyName] == true) ? 1.0 : 0.0
                        } else if parts[1] == "mouse" && parts.count > 3 {
                            vars[parts[2]] = Double(engineWin.mouseX)
                            vars[parts[3]] = Double(engineWin.mouseY)
                            if parts.count > 4 {
                                vars[parts[4]] = engineWin.mousePressed ? 1.0 : 0.0
                            }
                        }
                    }
                    
                case "3d":
                    if parts.count > 1 {
                        let sub3d = parts[1]
                        if sub3d == "init", let ctx = renderContext {
                            renderer3D.initRenderer(width: ctx.width, height: ctx.height)
                        } else if sub3d == "camera" && parts.count > 4 {
                            renderer3D.cameraPos.x = Float(getVal(parts[2]))
                            renderer3D.cameraPos.y = Float(getVal(parts[3]))
                            renderer3D.cameraPos.z = Float(getVal(parts[4]))
                        } else if sub3d == "cube" && parts.count > 6 {
                            let c = Mesh3D.createCube(id: parts[2], size: Float(getVal(parts[6])), color: getRandomColor())
                            c.posX = Float(getVal(parts[3])); c.posY = Float(getVal(parts[4])); c.posZ = Float(getVal(parts[5]))
                            renderer3D.meshes.append(c)
                        } else if sub3d == "pyramid" && parts.count > 6 {
                            let p = Mesh3D.createPyramid(id: parts[2], size: Float(getVal(parts[6])), color: getRandomColor())
                            p.posX = Float(getVal(parts[3])); p.posY = Float(getVal(parts[4])); p.posZ = Float(getVal(parts[5]))
                            renderer3D.meshes.append(p)
                        } else if sub3d == "plane" && parts.count > 6 {
                            let p = Mesh3D.createPlane(id: parts[2], size: Float(getVal(parts[6])), color: .darkGray)
                            p.posX = Float(getVal(parts[3])); p.posY = Float(getVal(parts[4])); p.posZ = Float(getVal(parts[5]))
                            renderer3D.meshes.append(p)
                        } else if sub3d == "sphere" && parts.count > 6 {
                            let r = parts.count > 7 ? Int(getVal(parts[7])) : 10
                            let s = parts.count > 8 ? Int(getVal(parts[8])) : 10
                            let sp = Mesh3D.createSphere(id: parts[2], radius: Float(getVal(parts[6])), rings: r, sectors: s, color: getRandomColor())
                            sp.posX = Float(getVal(parts[3])); sp.posY = Float(getVal(parts[4])); sp.posZ = Float(getVal(parts[5]))
                            renderer3D.meshes.append(sp)
                        } else if sub3d == "loadobj" && parts.count > 6 {
                            let o = Mesh3D.loadOBJ(id: parts[2], filepath: parts[6], color: getRandomColor())
                            o.posX = Float(getVal(parts[3])); o.posY = Float(getVal(parts[4])); o.posZ = Float(getVal(parts[5]))
                            renderer3D.meshes.append(o)
                        } else if sub3d == "rotate" && parts.count > 5 {
                            if let m = renderer3D.meshes.first(where: { $0.id == parts[2] }) {
                                m.rotX = Float(getVal(parts[3]))
                                m.rotY = Float(getVal(parts[4]))
                                m.rotZ = Float(getVal(parts[5]))
                            }
                        } else if sub3d == "scale" && parts.count > 5 {
                            if let m = renderer3D.meshes.first(where: { $0.id == parts[2] }) {
                                m.scaleX = Float(getVal(parts[3]))
                                m.scaleY = Float(getVal(parts[4]))
                                m.scaleZ = Float(getVal(parts[5]))
                            }
                        } else if sub3d == "render", let ctx = renderContext {
                            renderer3D.render(context: ctx, width: CGFloat(ctx.width), height: CGFloat(ctx.height))
                        }
                    }
                    
                case "draw":
                    if parts.count > 1, let ctx = renderContext {
                        let subDraw = parts[1]
                        if subDraw == "clear" && parts.count > 4 {
                            let c = NSColor(red: CGFloat(getVal(parts[2]))/255.0, green: CGFloat(getVal(parts[3]))/255.0, blue: CGFloat(getVal(parts[4]))/255.0, alpha: 1.0)
                            ctx.setFillColor(c.cgColor)
                            ctx.fill(CGRect(x: 0, y: 0, width: ctx.width, height: ctx.height))
                        } else if subDraw == "rect" && parts.count > 8 {
                            let c = NSColor(red: CGFloat(getVal(parts[6]))/255.0, green: CGFloat(getVal(parts[7]))/255.0, blue: CGFloat(getVal(parts[8]))/255.0, alpha: 1.0)
                            ctx.setFillColor(c.cgColor)
                            ctx.fill(CGRect(x: getVal(parts[2]), y: getVal(parts[3]), width: getVal(parts[4]), height: getVal(parts[5])))
                        } else if subDraw == "circle" && parts.count > 7 {
                            let rad = getVal(parts[4])
                            let c = NSColor(red: CGFloat(getVal(parts[5]))/255.0, green: CGFloat(getVal(parts[6]))/255.0, blue: CGFloat(getVal(parts[7]))/255.0, alpha: 1.0)
                            ctx.setFillColor(c.cgColor)
                            ctx.fillEllipse(in: CGRect(x: getVal(parts[2]) - rad, y: getVal(parts[3]) - rad, width: rad * 2, height: rad * 2))
                        } else if subDraw == "line" && parts.count > 8 {
                            let c = NSColor(red: CGFloat(getVal(parts[6]))/255.0, green: CGFloat(getVal(parts[7]))/255.0, blue: CGFloat(getVal(parts[8]))/255.0, alpha: 1.0)
                            ctx.setStrokeColor(c.cgColor)
                            ctx.setLineWidth(2)
                            ctx.beginPath()
                            ctx.move(to: CGPoint(x: getVal(parts[2]), y: getVal(parts[3])))
                            ctx.addLine(to: CGPoint(x: getVal(parts[4]), y: getVal(parts[5])))
                            ctx.strokePath()
                        } else if subDraw == "text" && parts.count > 7 {
                            let text = parts[4].replacingOccurrences(of: "_", with: " ")
                            let color = NSColor(red: CGFloat(getVal(parts[5]))/255.0, green: CGFloat(getVal(parts[6]))/255.0, blue: CGFloat(getVal(parts[7]))/255.0, alpha: 1.0)
                            drawTextOnContext(ctx: ctx, text: text, x: CGFloat(getVal(parts[2])), y: CGFloat(getVal(parts[3])), color: color)
                        } else if subDraw == "string" && parts.count > 7 {
                            let textToDraw = stringVars[parts[4]] ?? (vars[parts[4]] != nil ? String(vars[parts[4]]!) : "null")
                            let color = NSColor(red: CGFloat(getVal(parts[5]))/255.0, green: CGFloat(getVal(parts[6]))/255.0, blue: CGFloat(getVal(parts[7]))/255.0, alpha: 1.0)
                            drawTextOnContext(ctx: ctx, text: textToDraw, x: CGFloat(getVal(parts[2])), y: CGFloat(getVal(parts[3])), color: color)
                        } else if subDraw == "render" {
                            updateViewport()
                        }
                    }
                    
                case "audio":
                    if parts.count > 2 {
                        if parts[1] == "load" && parts.count > 3 {
                            let path = parts[3...].joined(separator: " ")
                            try? audioEngine.loadAudio(alias: parts[2], pathOrUrl: path)
                        } else if parts[1] == "play" {
                            let start = parts.count > 3 ? getVal(parts[3]) : 0
                            audioEngine.playAudio(alias: parts[2], startSeconds: start)
                        } else if parts[1] == "stop" {
                            audioEngine.stopAudio(alias: parts[2])
                        }
                    }
                    
                default:
                    break
                }
            } catch {
                log("Runtime Error line \(pc + 1): \(error.localizedDescription)", color: .red)
            }
            
            pc += 1
        }
        log(">>> Execution Finished.", color: .gray)
    }
    
    private func getVal(_ s: String) -> Double {
        if let v = vars[s] { return v }
        return Double(s) ?? 0.0
    }
    
    private func getRandomColor() -> NSColor {
        return NSColor(
            red: CGFloat.random(in: 0.2...1.0),
            green: CGFloat.random(in: 0.2...1.0),
            blue: CGFloat.random(in: 0.2...1.0),
            alpha: 1.0
        )
    }
    
    private func drawTextOnContext(ctx: CGContext, text: String, x: CGFloat, y: CGFloat, color: NSColor) {
        let font = NSFont(name: "Menlo", size: 12) ?? NSFont.userFixedPitchFont(ofSize: 12)!
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let attrStr = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrStr)
        
        ctx.saveGState()
        ctx.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)
        ctx.textPosition = CGPoint(x: x, y: y + 12)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
    
    private func updateViewport() {
        guard let ctx = renderContext, let imageRef = ctx.makeImage() else { return }
        let newImage = NSImage(cgImage: imageRef, size: NSSize(width: ctx.width, height: ctx.height))
        
        DispatchQueue.main.async { [weak self] in
            guard let engineWin = self?.engineWindow else { return }
            engineWin.viewport.currentImage = newImage
            engineWin.viewport.needsDisplay = true
        }
    }
}

// MARK: - WinterIDE Form & Application

public class WinterIDE: NSWindow, NSTextDelegate, NSWindowDelegate {
    private var editorView = NSTextView()
    private var consoleOut = NSTextView()
    private var splitView = NSSplitView()
    
    private var interpreter: WinterInterpreter!
    private var scriptThread: Thread?
    private var engineWindow: WinterEngineWindow?
    
    public init() {
        let contentRect = NSRect(x: 0, y: 0, width: 900, height: 700)
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "WinterCode v2.0 IDE (Swift macOS)"
        self.backgroundColor = .black
        self.center()
        self.delegate = self
        
        setupUI()
        interpreter = WinterInterpreter(form: self, console: consoleOut)
        
        editorView.string = """
# WinterCode (3D4s) Demo - Black & White aesthetic
message Initializing Winter Engine...
window title Space Exploration Demo
window size 800 600

3d init
3d cube player_cube 0 -1 5 1.0
3d pyramid enemy -3 0 10 1.5
3d sphere moon 5 5 15 2.0 16 16

set px = 0
set py = -1
set pz = 5
set rot = 0

array create bullets
sub shoot
    message Pew!
endsub

message Use W/A/S/D to move, Mouse Click to interact!
message Press Shift + R to Restart, ESC to Stop.

set isRunning = 1
while isRunning == 1
    draw clear 10 10 15
    
    input key W wDown
    input key S sDown
    input key A aDown
    input key D dDown
    
    if wDown == 1
        add pz 0.2
    endif
    if sDown == 1
        sub pz 0.2
    endif
    if aDown == 1
        sub px 0.2
    endif
    if dDown == 1
        add px 0.2
    endif

    3d camera px py pz
    
    add rot 0.03
    3d rotate player_cube rot rot 0
    3d rotate enemy 0 rot 0
    3d rotate moon rot 0 rot
    
    3d render

    input mouse mX mY mDown
    if mDown == 1
        draw circle mX mY 20 200 50 50
        call shoot
    endif
    
    draw text 10 10 ENG_V2.0_RUNNING 255 255 255
    draw text 10 30 POS_X: 200 200 200
    draw string 80 30 px 255 255 255
    
    draw render
    sleep 16
endwhile

message Program Ended.
end
"""
        highlightSyntax()
    }
    
    private func setupUI() {
        splitView.isVertical = false
        splitView.dividerStyle = .thin
        splitView.frame = self.contentView?.bounds ?? .zero
        splitView.autoresizingMask = [.width, .height]
        
        let editorScrollView = NSTextView.scrollableTextView()
        editorView = editorScrollView.documentView as! NSTextView
        editorView.backgroundColor = .black
        editorView.textColor = .white
        editorView.font = NSFont(name: "Menlo", size: 13) ?? NSFont.userFixedPitchFont(ofSize: 13)
        editorView.isAutomaticQuoteSubstitutionEnabled = false
        editorView.delegate = self
        
        let consoleScrollView = NSTextView.scrollableTextView()
        consoleOut = consoleScrollView.documentView as! NSTextView
        consoleOut.backgroundColor = .black
        consoleOut.textColor = .lightGray
        consoleOut.font = NSFont(name: "Menlo", size: 12) ?? NSFont.userFixedPitchFont(ofSize: 12)
        consoleOut.isEditable = false
        
        splitView.addSubview(editorScrollView)
        splitView.addSubview(consoleScrollView)
        self.contentView?.addSubview(splitView)
        
        setupMenu()
    }
    
    private func setupMenu() {
        let mainMenu = NSMenu()
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        
        fileMenu.addItem(withTitle: "Open...", action: #selector(openFile), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Save...", action: #selector(saveFile), keyEquivalent: "s")
        fileMenuItem.submenu = fileMenu
        
        let runMenuItem = NSMenuItem(title: "Run Script", action: #selector(runMenuClick), keyEquivalent: "R")
        runMenuItem.keyEquivalentModifierMask = [.shift]
        
        let stopMenuItem = NSMenuItem(title: "Stop", action: #selector(stopMenuClick), keyEquivalent: "\u{1b}")
        stopMenuItem.keyEquivalentModifierMask = []
        
        mainMenu.addItem(fileMenuItem)
        mainMenu.addItem(runMenuItem)
        mainMenu.addItem(stopMenuItem)
        NSApp.mainMenu = mainMenu
    }
    
    public func textDidChange(_ notification: Notification) {
        highlightSyntax()
    }
    
    private func highlightSyntax() {
        guard let textStorage = editorView.textStorage else { return }
        let rawText = editorView.string
        let fullRange = NSRange(location: 0, length: rawText.utf16.count)
        
        textStorage.addAttribute(.foregroundColor, value: NSColor.white, range: fullRange)
        
        let keywords = ["message", "window", "set", "add", "sub", "mul", "div", "if", "else", "endif", "while", "endwhile", "repeat", "endrepeat", "sleep", "input", "file", "draw", "3d", "audio", "end", "call", "array"]
        let keywordPattern = "\\b(" + keywords.joined(separator: "|") + ")\\b"
        applyRegexHighlight(pattern: keywordPattern, color: NSColor(red: 86/255.0, green: 156/255.0, blue: 214/255.0, alpha: 1.0), in: rawText, textStorage: textStorage)
        
        applyRegexHighlight(pattern: "\\b(math|sin|cos|tan|sqrt|rnd)\\b", color: NSColor(red: 197/255.0, green: 134/255.0, blue: 192/255.0, alpha: 1.0), in: rawText, textStorage: textStorage)
        applyRegexHighlight(pattern: "\\b-?\\d+(\\.\\d+)?\\b", color: NSColor(red: 181/255.0, green: 206/255.0, blue: 168/255.0, alpha: 1.0), in: rawText, textStorage: textStorage)
        applyRegexHighlight(pattern: "#.*", color: NSColor(red: 87/255.0, green: 166/255.0, blue: 74/255.0, alpha: 1.0), in: rawText, textStorage: textStorage)
    }
    
    private func applyRegexHighlight(pattern: String, color: NSColor, in text: String, textStorage: NSTextStorage) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            textStorage.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }
    
    @objc private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["wc", "txt"]
        if panel.runModal() == .OK, let url = panel.url, let content = try? String(contentsOf: url) {
            editorView.string = content
            highlightSyntax()
        }
    }
    
    @objc private func saveFile() {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["wc"]
        if panel.runModal() == .OK, let url = panel.url {
            try? editorView.string.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    @objc private func runMenuClick() {
        let code = editorView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !code.hasSuffix("end") {
            interpreter.log("Error: Скрипт ОБЯЗАТЕЛЬНО должен заканчиваться командой 'end'.", color: .red)
            return
        }
        
        if let thread = scriptThread, thread.isExecuting {
            interpreter.stop()
            engineWindow?.close()
        }
        
        consoleOut.string = ""
        interpreter.log(">>> Compilation Started...", color: .cyan)
        
        let engineWin = WinterEngineWindow()
        self.engineWindow = engineWin
        engineWin.makeKeyAndOrderFront(nil)
        
        interpreter.setOutputWindow(engineWin)
        
        scriptThread = Thread { [weak self] in
            self?.interpreter.run(code: code)
        }
        scriptThread?.start()
    }
    
    @objc private func stopMenuClick() {
        if let thread = scriptThread, thread.isExecuting {
            interpreter.stop()
            interpreter.log(">>> Engine forcefully stopped by user.", color: .orange)
        }
    }
    
    public func windowWillClose(_ notification: Notification) {
        interpreter.stop()
    }
}

// MARK: - App Main Entry Point

class AppDelegate: NSObject, NSApplicationDelegate {
    var ideWindow: WinterIDE?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        ideWindow = WinterIDE()
        ideWindow?.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
