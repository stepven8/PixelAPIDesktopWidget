import AppKit

final class GlassPanelView: NSView {
    override var isOpaque: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        canDrawSubviewsIntoLayer = true
        layer?.cornerRadius = 26
        layer?.masksToBounds = false
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
        layer?.shadowOpacity = 0
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 26, yRadius: 26)

        let background = NSGradient(colors: [
            NSColor(calibratedRed: 0.065, green: 0.105, blue: 0.165, alpha: 0.98),
            NSColor(calibratedRed: 0.115, green: 0.175, blue: 0.255, alpha: 0.95),
            NSColor(calibratedRed: 0.035, green: 0.055, blue: 0.095, alpha: 0.99)
        ])
        background?.draw(in: path, angle: 238)

        let glow = NSBezierPath(roundedRect: bounds.insetBy(dx: 12, dy: 10), xRadius: 22, yRadius: 22)
        NSColor(calibratedRed: 0.35, green: 0.65, blue: 1.0, alpha: 0.055).setFill()
        glow.fill()

        NSColor.white.withAlphaComponent(0.16).setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}

final class MetricTileView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private let accent = NSView()

    init(title: String, accentColor: NSColor) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 18
        layer?.backgroundColor = NSColor(calibratedRed: 0.33, green: 0.43, blue: 0.55, alpha: 0.38).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor
        layer?.borderWidth = 1

        accent.wantsLayer = true
        accent.layer?.backgroundColor = accentColor.cgColor
        accent.layer?.cornerRadius = 3
        accent.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accent)

        titleLabel.stringValue = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.68)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        valueLabel.font = .monospacedDigitSystemFont(ofSize: 24, weight: .semibold)
        valueLabel.textColor = .white
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.maximumNumberOfLines = 1
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            accent.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            accent.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            accent.widthAnchor.constraint(equalToConstant: 6),
            accent.heightAnchor.constraint(equalToConstant: 6),

            titleLabel.leadingAnchor.constraint(equalTo: accent.trailingAnchor, constant: 7),
            titleLabel.centerYAnchor.constraint(equalTo: accent.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),

            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setValue(_ value: String) {
        valueLabel.stringValue = value
    }
}

final class PillButton: NSButton {
    init(title: String) {
        super.init(frame: .zero)
        self.title = title
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = NSColor(calibratedRed: 0.42, green: 0.50, blue: 0.60, alpha: 0.32).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(0.18).cgColor
        layer?.borderWidth = 1
        contentTintColor = .white
        font = .systemFont(ofSize: 12, weight: .semibold)
        bezelStyle = .regularSquare
        setButtonType(.momentaryPushIn)
    }

    required init?(coder: NSCoder) {
        nil
    }
}

final class StatusDotView: NSView {
    var color: NSColor = NSColor(calibratedRed: 0.28, green: 0.95, blue: 0.62, alpha: 1) {
        didSet { layer?.backgroundColor = color.cgColor }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.backgroundColor = color.cgColor
        layer?.shadowColor = color.cgColor
        layer?.shadowOpacity = 0.75
        layer?.shadowRadius = 7
        layer?.shadowOffset = .zero
    }

    required init?(coder: NSCoder) {
        nil
    }
}

extension Double {
    var compactTokenString: String {
        if self >= 1_000_000 { return String(format: "%.1fM", self / 1_000_000) }
        if self >= 1_000 { return String(format: "%.1fK", self / 1_000) }
        return String(format: "%.0f", self)
    }

    var moneyString: String {
        String(format: "$%.2f", self)
    }
}
