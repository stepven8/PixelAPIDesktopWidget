import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var panel: NSWindow!
    private let widgetController = WidgetViewController()
    private var loginWindowController: LoginWindowController?
    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var credentials: PixelCredentials?
    private var latestMetrics = WidgetMetrics.placeholder

    private let frameKey = "widgetFrame"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        createPanel()
        wireActions()
        restoreCredentials()
        refreshNow()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.refreshNow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveFrame()
    }

    func windowDidMove(_ notification: Notification) {
        saveFrame()
    }

    func windowDidResize(_ notification: Notification) {
        saveFrame()
    }

    private func createPanel() {
        let defaultSize = NSSize(width: 360, height: 250)
        let defaultFrame = NSRect(x: 84, y: 512, width: defaultSize.width, height: defaultSize.height)
        let savedFrame = UserDefaults.standard.string(forKey: frameKey).flatMap(NSRectFromString).map {
            NSRect(origin: $0.origin, size: defaultSize)
        }

        panel = NSWindow(
            contentRect: savedFrame ?? defaultFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.title = "Pixel API Widget"
        panel.contentViewController = widgetController
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.canHide = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    private func wireActions() {
        widgetController.onLoginRequested = { [weak self] in
            self?.showLogin()
        }
        widgetController.onRefreshRequested = { [weak self] in
            self?.refreshNow()
        }
    }

    private func restoreCredentials() {
        credentials = try? KeychainStore.shared.load()
        if credentials == nil {
            widgetController.update(metrics: latestMetrics, status: .signedOut)
        }
    }

    private func showLogin() {
        NSApp.activate(ignoringOtherApps: true)
        let controller = LoginWindowController()
        controller.onLogin = { [weak self] email, password in
            guard let self else { return }
            let credentials = try await APIClient.shared.login(email: email, password: password)
            try KeychainStore.shared.save(credentials)
            await MainActor.run {
                self.credentials = credentials
                self.refreshNow()
            }
        }
        loginWindowController = controller
        controller.showWindow(nil)
    }

    private func refreshNow() {
        if refreshTask != nil {
            return
        }

        guard let credentials else {
            widgetController.update(metrics: latestMetrics, status: .signedOut)
            return
        }

        widgetController.update(metrics: latestMetrics, status: .loading)

        refreshTask = Task { [weak self] in
            guard let self else { return }
            defer {
                Task { @MainActor in
                    self.refreshTask = nil
                }
            }
            do {
                let metrics = try await APIClient.shared.metrics(using: credentials)
                await MainActor.run {
                    self.latestMetrics = metrics
                    self.widgetController.update(metrics: metrics, status: .ready)
                }
            } catch APIError.unauthorized {
                await self.refreshAfterUnauthorized()
            } catch {
                await MainActor.run {
                    self.widgetController.update(metrics: self.latestMetrics, status: .networkError(Self.shortErrorMessage(error)))
                }
            }
        }
    }

    private func refreshAfterUnauthorized() async {
        guard let credentials else { return }
        do {
            let refreshed = try await APIClient.shared.refresh(credentials)
            try KeychainStore.shared.save(refreshed)
            let metrics = try await APIClient.shared.metrics(using: refreshed)
            await MainActor.run {
                self.credentials = refreshed
                self.latestMetrics = metrics
                self.widgetController.update(metrics: metrics, status: .ready)
            }
        } catch {
            KeychainStore.shared.delete()
            await MainActor.run {
                self.credentials = nil
                self.widgetController.update(metrics: self.latestMetrics, status: .authExpired)
            }
        }
    }

    private func saveFrame() {
        guard let panel else { return }
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: frameKey)
    }

    private static func shortErrorMessage(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL: return "接口地址错误"
            case .unauthorized: return "登录已失效"
            case .invalidResponse: return "响应解析失败"
            case .server(let message): return message
            }
        }
        return "网络异常"
    }
}
