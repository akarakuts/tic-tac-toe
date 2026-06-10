import Cocoa
import SpriteKit

// EN: Hosts the SpriteKit scene inside an SKView and keeps scene size in sync with Auto Layout.
// RU: Обёртка для SpriteKit-сцены в SKView; синхронизирует размер сцены с Auto Layout.

@MainActor
final class ViewController: NSViewController {

    @IBOutlet var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let view = skView else { return }

        // EN: Storyboard SKView had a fixed frame without resizing masks — small windows clipped the left HUD column.
        // RU: SKView из storyboard имел фиксированный frame без springs — при маленьком окне обрезалась левая колонка интерфейса.
        view.autoresizingMask = [.width, .height]

        let scene = GameScene(size: view.bounds.size)
        // EN: One logical unit per point — avoids aspect-fill cropping of HUD and board.
        // RU: Один логический юнит на поинт — без обрезки колонок и поля как при aspect-fill.
        scene.scaleMode = .resizeFill

        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false

        view.setAccessibilityElement(true)
        view.setAccessibilityHelp(L10n.accessibilityKeyboardHelp)
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        if let scene = skView?.scene as? GameScene {
            scene.keyDown(with: event)
        } else {
            super.keyDown(with: event)
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        guard let view = skView, let scene = view.scene as? GameScene else { return }
        let bounds = view.bounds.size
        // EN: Ignore degenerate sizes during early layout passes.
        // RU: Игнорируем нулевые размеры на ранних этапах раскладки.
        guard bounds.width > 1, bounds.height > 1 else { return }
        scene.size = bounds
    }
}
