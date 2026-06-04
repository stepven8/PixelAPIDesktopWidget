import AppKit

final class WidgetViewController: NSViewController {
    var onLoginRequested: (() -> Void)?

    private let titleLabel = NSTextField(labelWithString: "Pixel API")
    private let statusLabel = NSTextField(labelWithString: "需要登录")
    private let timeLabel = NSTextField(labelWithString: "点击登录后开始同步")
    private let statusDot = StatusDotView()
    private let loginButton = PillButton(title: "登录")
    private let refreshButton = PillButton(title: "刷新")

    private let balanceTile = MetricTileView(title: "余额", accentColor: NSColor(calibratedRed: 0.39, green: 0.73, blue: 1.00, alpha: 1))
    private let spendTile = MetricTileView(title: "今日消费", accentColor: NSColor(calibratedRed: 1.00, green: 0.74, blue: 0.33, alpha: 1))
    private let todayTokenTile = MetricTileView(title: "今日 Token", accentColor: NSColor(calibratedRed: 0.39, green: 0.95, blue: 0.65, alpha: 1))
    private let totalTokenTile = MetricTileView(title: "累计 Token", accentColor: NSColor(calibratedRed: 0.76, green: 0.65, blue: 1.00, alpha: 1))

    var onRefreshRequested: (() -> Void)?

    override func loadView() {
        view = GlassPanelView(frame: NSRect(x: 0, y: 0, width: 360, height: 250))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        update(metrics: .placeholder, status: .signedOut)
    }

    func update(metrics: WidgetMetrics, status: WidgetStatus) {
        balanceTile.setValue(metrics.balance.moneyString)
        spendTile.setValue(metrics.todaySpend.moneyString)
        todayTokenTile.setValue(metrics.todayTokens.compactTokenString)
        totalTokenTile.setValue(metrics.totalTokens.compactTokenString)

        statusLabel.stringValue = status.label
        timeLabel.stringValue = "更新于 \(Self.timeFormatter.string(from: metrics.updatedAt))"

        switch status {
        case .ready:
            statusDot.color = NSColor(calibratedRed: 0.28, green: 0.95, blue: 0.62, alpha: 1)
            loginButton.title = "账号"
        case .loading:
            statusDot.color = NSColor(calibratedRed: 0.43, green: 0.73, blue: 1.00, alpha: 1)
        case .networkError:
            statusDot.color = NSColor(calibratedRed: 1.00, green: 0.72, blue: 0.33, alpha: 1)
        case .authExpired, .signedOut:
            statusDot.color = NSColor(calibratedRed: 1.00, green: 0.38, blue: 0.42, alpha: 1)
            loginButton.title = "登录"
        }
    }

    private func buildUI() {
        let root = view

        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(titleTapped)))
        root.addSubview(titleLabel)

        statusDot.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(statusDot)

        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textColor = NSColor.white.withAlphaComponent(0.72)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(statusLabel)

        loginButton.target = self
        loginButton.action = #selector(loginTapped)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(loginButton)

        refreshButton.target = self
        refreshButton.action = #selector(refreshTapped)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(refreshButton)

        let topRow = NSStackView(views: [balanceTile, spendTile])
        topRow.orientation = .horizontal
        topRow.spacing = 12
        topRow.distribution = .fillEqually
        topRow.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(topRow)

        let bottomRow = NSStackView(views: [todayTokenTile, totalTokenTile])
        bottomRow.orientation = .horizontal
        bottomRow.spacing = 12
        bottomRow.distribution = .fillEqually
        bottomRow.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bottomRow)

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        timeLabel.textColor = NSColor.white.withAlphaComponent(0.50)
        timeLabel.alignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 24),
            titleLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 17),

            statusDot.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusDot.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),

            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: statusDot.centerYAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 70),

            refreshButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            refreshButton.topAnchor.constraint(equalTo: root.topAnchor, constant: 18),
            refreshButton.widthAnchor.constraint(equalToConstant: 56),
            refreshButton.heightAnchor.constraint(equalToConstant: 29),

            loginButton.trailingAnchor.constraint(equalTo: refreshButton.leadingAnchor, constant: -8),
            loginButton.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 56),
            loginButton.heightAnchor.constraint(equalToConstant: 29),

            topRow.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
            topRow.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            topRow.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 15),
            topRow.heightAnchor.constraint(equalToConstant: 68),

            bottomRow.leadingAnchor.constraint(equalTo: topRow.leadingAnchor),
            bottomRow.trailingAnchor.constraint(equalTo: topRow.trailingAnchor),
            bottomRow.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 10),
            bottomRow.heightAnchor.constraint(equalToConstant: 68),

            timeLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 8),
            timeLabel.centerYAnchor.constraint(equalTo: statusDot.centerYAnchor)
        ])
    }

    @objc private func loginTapped() {
        onLoginRequested?()
    }

    @objc private func refreshTapped() {
        onRefreshRequested?()
    }

    @objc private func titleTapped() {
        guard let dashboardURL = URL(string: "https://ai-pixel.online/dashboard") else {
            return
        }

        let workspace = NSWorkspace.shared
        guard let chromeURL = workspace.urlForApplication(withBundleIdentifier: "com.google.Chrome") else {
            workspace.open(dashboardURL)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        workspace.open([dashboardURL], withApplicationAt: chromeURL, configuration: configuration) { _, error in
            if error != nil {
                workspace.open(dashboardURL)
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
