import UIKit
import WebKit
import AVFoundation

final class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    private let homeURL = URL(string: "https://www.jhcmzy.top/dongli/")!
    private var webView: WKWebView!
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let errorView = UIStackView()
    private let errorLabel = UILabel()

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.backgroundColor = .systemBackground
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)

        errorLabel.text = "冻梨AI 暂时无法连接"
        errorLabel.textColor = .secondaryLabel
        errorLabel.font = .systemFont(ofSize: 15)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        let retry = UIButton(type: .system)
        retry.setTitle("重新连接", for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        retry.addTarget(self, action: #selector(reloadHome), for: .touchUpInside)

        errorView.axis = .vertical
        errorView.alignment = .center
        errorView.spacing = 14
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.addArrangedSubview(errorLabel)
        errorView.addArrangedSubview(retry)
        errorView.isHidden = true
        view.addSubview(errorView)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            errorView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: 24)
        ])

        webView.load(URLRequest(url: homeURL))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureAudioSession()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try? session.setActive(true)
    }

    @objc private func reloadHome() {
        errorView.isHidden = true
        webView.load(URLRequest(url: homeURL))
    }

    private func isTrusted(host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return host == "jhcmzy.top"
            || host == "www.jhcmzy.top"
            || host.hasSuffix(".jhcmzy.top")
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        errorView.isHidden = true
        spinner.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        errorView.isHidden = true
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        spinner.stopAnimating()
        showError(error.localizedDescription)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        spinner.stopAnimating()
        showError(error.localizedDescription)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if isTrusted(host: url.host) {
            decisionHandler(.allow)
            return
        }

        UIApplication.shared.open(url)
        decisionHandler(.cancel)
    }

    private func showError(_ message: String) {
        errorLabel.text = "冻梨AI 暂时无法连接\n\(message)"
        errorView.isHidden = false
    }

    // MARK: - WKUIDelegate

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        guard isTrusted(host: origin.host) else {
            decisionHandler(.deny)
            return
        }

        switch type {
        case .microphone:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    decisionHandler(granted ? .grant : .deny)
                }
            }

        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    decisionHandler(granted ? .grant : .deny)
                }
            }

        case .cameraAndMicrophone:
            requestCameraAndMicrophone(decisionHandler: decisionHandler)

        @unknown default:
            decisionHandler(.deny)
        }
    }

    private func requestCameraAndMicrophone(
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
            guard micGranted else {
                DispatchQueue.main.async { decisionHandler(.deny) }
                return
            }

            AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
                DispatchQueue.main.async {
                    decisionHandler(cameraGranted ? .grant : .deny)
                }
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: "冻梨AI", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(title: "冻梨AI", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler(true)
        })
        present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let alert = UIAlertController(title: "冻梨AI", message: prompt, preferredStyle: .alert)
        alert.addTextField { field in
            field.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(nil)
        })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }
}
