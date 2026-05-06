import AVFoundation
import Foundation

// EN: Lightweight synthesized UI bleeps — no bundled audio assets; runs on the main thread only.
// RU: Лёгкие синтезированные звуки интерфейса без ресурсов в бандле; только на главном потоке.

@MainActor
final class GameSoundFX {

    static let shared = GameSoundFX()

    /// EN: Mirrors persisted user preference — scene updates on launch and when toggling HUD.
    /// RU: Отражает сохранённую настройку — сцена обновляет при запуске и при переключении в HUD.
    var soundEffectsEnabled = true

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1
        do {
            try engine.start()
        } catch {
            // EN: Silent fallback if audio hardware unavailable.
            // RU: Тихий отказ, если аудио недоступно.
        }
    }

    func playMoveTap() {
        playTone(frequency: 920, duration: 0.038, volume: 0.14)
    }

    func playWinFanfare() {
        playTone(frequency: 523.25, duration: 0.09, volume: 0.16)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) { [weak self] in
            self?.playTone(frequency: 659.25, duration: 0.1, volume: 0.17)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.19) { [weak self] in
            self?.playTone(frequency: 783.99, duration: 0.14, volume: 0.18)
        }
    }

    func playInvalidMove() {
        playTone(frequency: 165, duration: 0.11, volume: 0.22)
    }

    private func playTone(frequency: Double, duration: Double, volume: Float) {
        guard soundEffectsEnabled else { return }
        guard duration > 0, let buffer = makeSineBuffer(frequency: frequency, duration: duration, volume: volume) else {
            return
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    private func makeSineBuffer(frequency: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let ch = buffer.floatChannelData else { return nil }
        let ptr = ch[0]

        let twoPi = 2 * Double.pi
        let attack = sampleRate * 0.004
        let release = sampleRate * 0.022
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var env = 1.0
            if Double(i) < attack {
                env = Double(i) / attack
            }
            let tailStart = Double(frameCount) - release
            if Double(i) > tailStart {
                env *= max(0, (Double(frameCount) - Double(i)) / release)
            }
            ptr[i] = Float(sin(twoPi * frequency * t) * env * Double(volume))
        }
        return buffer
    }
}
