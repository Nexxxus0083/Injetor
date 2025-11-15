//
//  WebViewController.swift
//  MemoryInjector
//
//  View Controller que gerencia o WKWebView com a interface HTML
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var jsBridge: JSBridge!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadInterface()
    }
    
    private func setupWebView() {
        // Configuração do WKWebView
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true
        
        // Adicionar handler para alert
        config.userContentController.add(self, name: "showAlert")
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = true
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.layer.cornerRadius = 10
        webView.layer.masksToBounds = true
        
        view.addSubview(webView)
        
        // Auto Layout
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Inicializar JSBridge
        jsBridge = JSBridge(webView: webView)
    }
    
    private func loadInterface() {
        // Carregar o HTML da interface
        if let htmlPath = Bundle.main.path(forResource: "interface", ofType: "html") {
            let htmlURL = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        } else {
            // Fallback: carregar HTML inline se o arquivo não existir
            loadFallbackHTML()
        }
    }
    
    private func loadFallbackHTML() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Memory Injector</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    background: rgba(0, 0, 0, 0.9);
                    color: white;
                    padding: 20px;
                }
                .container {
                    max-width: 400px;
                    margin: 0 auto;
                }
                h1 {
                    text-align: center;
                    color: #ba071c;
                    margin-bottom: 20px;
                    font-size: 24px;
                }
                .status {
                    background: rgba(255, 255, 255, 0.1);
                    padding: 15px;
                    border-radius: 8px;
                    margin-bottom: 20px;
                }
                .button {
                    background: #ba071c;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 6px;
                    font-size: 16px;
                    width: 100%;
                    margin-bottom: 10px;
                    cursor: pointer;
                }
                .button:active {
                    opacity: 0.8;
                }
                .info {
                    text-align: center;
                    margin-top: 20px;
                    font-size: 14px;
                    opacity: 0.7;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🎮 Memory Injector</h1>
                
                <div class="status">
                    <p><strong>Status:</strong> <span id="status">Aguardando...</span></p>
                    <p><strong>Processo:</strong> <span id="process">Nenhum</span></p>
                </div>
                
                <button class="button" onclick="testAttach()">🔗 Anexar ao Processo</button>
                <button class="button" onclick="testSearch()">🔍 Testar Busca</button>
                <button class="button" onclick="showInfo()">ℹ️ Informações</button>
                
                <div class="info">
                    <p>Memory Injector v1.0</p>
                    <p>Desenvolvido para TrollStore</p>
                </div>
            </div>
            
            <script>
                function testAttach() {
                    // Exemplo: anexar ao processo do jogo
                    h5gg.attachProcess('SpringBoard');
                    alert('Tentando anexar ao processo...');
                    updateStatus();
                }
                
                function testSearch() {
                    if (!h5gg.isAttached()) {
                        alert('Anexe a um processo primeiro!');
                        return;
                    }
                    
                    h5gg.searchNumber('100', 'I32', '0x100000000', '0x160000000');
                    const count = h5gg.getResultsCount();
                    alert('Encontrados ' + count + ' resultados');
                }
                
                function showInfo() {
                    const info = h5gg.getProcessInfo();
                    alert(info || 'Nenhum processo anexado');
                }
                
                function updateStatus() {
                    const attached = h5gg.isAttached();
                    document.getElementById('status').textContent = attached ? 'Conectado ✅' : 'Desconectado ❌';
                    
                    if (attached) {
                        const info = h5gg.getProcessInfo();
                        const lines = info.split('\\n');
                        const pidLine = lines.find(l => l.startsWith('PID:'));
                        if (pidLine) {
                            document.getElementById('process').textContent = pidLine.replace('PID: ', '');
                        }
                    } else {
                        document.getElementById('process').textContent = 'Nenhum';
                    }
                }
                
                // Atualizar status a cada 2 segundos
                setInterval(updateStatus, 2000);
                updateStatus();
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "showAlert" {
            if let body = message.body as? [String: Any],
               let alertMessage = body["message"] as? String {
                showAlert(message: alertMessage)
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Memory Injector", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Apresentar o alert na window principal
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ Interface loaded successfully")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ Failed to load interface: \(error.localizedDescription)")
    }
    
    // MARK: - Cleanup
    
    deinit {
        jsBridge?.cleanup()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "showAlert")
    }
}
