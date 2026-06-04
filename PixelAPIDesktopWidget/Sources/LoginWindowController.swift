import AppKit

final class LoginWindowController: NSWindowController {
    var onLogin: ((String, String) async throws -> Void)?

    private let emailField = NSTextField()
    private let passwordField = NSSecureTextField()
    private let statusLabel = NSTextField(labelWithString: "")
    private let loginButton = NSButton(title: "登录并保存", target: nil, action: nil)

    init() {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 250))
        let window = NSWindow(
            contentRect: content.frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "登录 Pixel API"
        window.contentView = content
        window.center()
        super.init(window: window)
        buildUI(in: content)
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func buildUI(in root: NSView) {
        let title = NSTextField(labelWithString: "Pixel API 登录")
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(title)

        let subtitle = NSTextField(labelWithString: "密码只用于本次登录，token 保存到 macOS Keychain。")
        subtitle.font = .systemFont(ofSize: 12, weight: .regular)
        subtitle.textColor = .secondaryLabelColor
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(subtitle)

        emailField.placeholderString = "邮箱"
        emailField.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(emailField)

        passwordField.placeholderString = "密码"
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(passwordField)

        loginButton.target = self
        loginButton.action = #selector(loginTapped)
        loginButton.bezelStyle = .rounded
        loginButton.keyEquivalent = "\r"
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(loginButton)

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 28),
            title.topAnchor.constraint(equalTo: root.topAnchor, constant: 24),

            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -28),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),

            emailField.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            emailField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -28),
            emailField.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 22),
            emailField.heightAnchor.constraint(equalToConstant: 32),

            passwordField.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 10),
            passwordField.heightAnchor.constraint(equalToConstant: 32),

            loginButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),
            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 18),
            loginButton.widthAnchor.constraint(equalToConstant: 112),

            statusLabel.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: loginButton.leadingAnchor, constant: -12),
            statusLabel.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])
    }

    @objc private func loginTapped() {
        let email = emailField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.stringValue
        guard !email.isEmpty, !password.isEmpty else {
            statusLabel.stringValue = "请输入邮箱和密码"
            return
        }

        loginButton.isEnabled = false
        statusLabel.stringValue = "正在登录..."

        Task { @MainActor in
            do {
                try await onLogin?(email, password)
                statusLabel.stringValue = "登录成功"
                close()
            } catch {
                statusLabel.stringValue = "登录失败：\(error.localizedDescription)"
                loginButton.isEnabled = true
            }
        }
    }
}
