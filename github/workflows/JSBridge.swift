//
//  JSBridge.swift
//  MemoryInjector
//
//  Ponte de comunicação entre JavaScript e código nativo
//

import Foundation
import WebKit

class JSBridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    private let memoryEngine = MemoryEngine.shared
    
    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        setupMessageHandlers()
    }
    
    // MARK: - Setup
    
    private func setupMessageHandlers() {
        guard let webView = webView else { return }
        
        let handlers = [
            "searchNumber",
            "editAll",
            "setValue",
            "getResults",
            "getResultsCount",
            "clearResults",
            "searchNearby",
            "attachProcess",
            "detachProcess",
            "isAttached",
            "getProcessInfo"
        ]
        
        for handler in handlers {
            webView.configuration.userContentController.add(self, name: handler)
        }
        
        injectH5GGScript()
    }
    
    // MARK: - Message Handler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        
        switch message.name {
        case "searchNumber":
            handleSearchNumber(body)
        case "editAll":
            handleEditAll(body)
        case "setValue":
            handleSetValue(body)
        case "getResults":
            handleGetResults(body)
        case "getResultsCount":
            handleGetResultsCount()
        case "clearResults":
            handleClearResults()
        case "searchNearby":
            handleSearchNearby(body)
        case "attachProcess":
            handleAttachProcess(body)
        case "detachProcess":
            handleDetachProcess()
        case "isAttached":
            handleIsAttached()
        case "getProcessInfo":
            handleGetProcessInfo()
        default:
            break
        }
    }
    
    // MARK: - Handlers
    
    private func handleSearchNumber(_ params: [String: Any]) {
        guard let value = params["value"] as? String,
              let type = params["type"] as? String,
              let startAddr = params["startAddr"] as? String,
              let endAddr = params["endAddr"] as? String else { return }
        
        let count = memoryEngine.searchNumber(value, type, startAddr, endAddr)
        callJSCallback(params["callback"] as? String, result: count)
    }
    
    private func handleEditAll(_ params: [String: Any]) {
        guard let value = params["value"] as? String,
              let type = params["type"] as? String else { return }
        
        let count = memoryEngine.editAll(value, type)
        callJSCallback(params["callback"] as? String, result: count)
    }
    
    private func handleSetValue(_ params: [String: Any]) {
        guard let address = params["address"] as? String,
              let value = params["value"] as? String,
              let type = params["type"] as? String else { return }
        
        let success = memoryEngine.setValue(address, value, type)
        callJSCallback(params["callback"] as? String, result: success)
    }
    
    private func handleGetResults(_ params: [String: Any]) {
        guard let count = params["count"] as? Int else { return }
        
        let results = memoryEngine.getResults(count)
        callJSCallback(params["callback"] as? String, result: results)
    }
    
    private func handleGetResultsCount() {
        let count = memoryEngine.getResultsCount()
        executeJS("window._h5gg_resultsCount = \(count);")
    }
    
    private func handleClearResults() {
        memoryEngine.clearResults()
    }
    
    private func handleSearchNearby(_ params: [String: Any]) {
        guard let value = params["value"] as? String,
              let type = params["type"] as? String,
              let offset = params["offset"] as? String else { return }
        
        let count = memoryEngine.searchNearby(value, type, offset)
        callJSCallback(params["callback"] as? String, result: count)
    }
    
    private func handleAttachProcess(_ params: [String: Any]) {
        if let processName = params["name"] as? String {
            let success = memoryEngine.attachProcess(processName)
            callJSCallback(params["callback"] as? String, result: success)
        } else if let pid = params["pid"] as? Int32 {
            let success = memoryEngine.attachProcess(pid: pid)
            callJSCallback(params["callback"] as? String, result: success)
        }
    }
    
    private func handleDetachProcess() {
        memoryEngine.detachProcess()
    }
    
    private func handleIsAttached() {
        let attached = memoryEngine.isAttached()
        executeJS("window._h5gg_isAttached = \(attached);")
    }
    
    private func handleGetProcessInfo() {
        let info = memoryEngine.getProcessInfo()
        let escaped = info.replacingOccurrences(of: "\n", with: "\\n")
        executeJS("window._h5gg_processInfo = '\(escaped)';")
    }
    
    // MARK: - JavaScript Injection
    
    private func injectH5GGScript() {
        let script = """
        // h5gg API Implementation
        window.h5gg = {
            searchNumber: function(value, type, startAddr, endAddr) {
                webkit.messageHandlers.searchNumber.postMessage({
                    value: value.toString(),
                    type: type,
                    startAddr: startAddr,
                    endAddr: endAddr
                });
            },
            
            editAll: function(value, type) {
                webkit.messageHandlers.editAll.postMessage({
                    value: value.toString(),
                    type: type
                });
            },
            
            setValue: function(address, value, type) {
                webkit.messageHandlers.setValue.postMessage({
                    address: address,
                    value: value.toString(),
                    type: type
                });
            },
            
            getResults: function(count) {
                webkit.messageHandlers.getResults.postMessage({
                    count: count
                });
                return window._h5gg_results || [];
            },
            
            getResultsCount: function() {
                webkit.messageHandlers.getResultsCount.postMessage({});
                return window._h5gg_resultsCount || 0;
            },
            
            clearResults: function() {
                webkit.messageHandlers.clearResults.postMessage({});
            },
            
            searchNearby: function(value, type, offset) {
                webkit.messageHandlers.searchNearby.postMessage({
                    value: value.toString(),
                    type: type,
                    offset: offset
                });
            },
            
            attachProcess: function(nameOrPid) {
                if (typeof nameOrPid === 'string') {
                    webkit.messageHandlers.attachProcess.postMessage({
                        name: nameOrPid
                    });
                } else {
                    webkit.messageHandlers.attachProcess.postMessage({
                        pid: nameOrPid
                    });
                }
            },
            
            detachProcess: function() {
                webkit.messageHandlers.detachProcess.postMessage({});
            },
            
            isAttached: function() {
                webkit.messageHandlers.isAttached.postMessage({});
                return window._h5gg_isAttached || false;
            },
            
            getProcessInfo: function() {
                webkit.messageHandlers.getProcessInfo.postMessage({});
                return window._h5gg_processInfo || '';
            }
        };
        
        // Override alert to show native alerts
        window.alert = function(message) {
            webkit.messageHandlers.showAlert.postMessage({
                message: message
            });
        };
        
        console.log('✅ h5gg API initialized');
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView?.configuration.userContentController.addUserScript(userScript)
    }
    
    // MARK: - JavaScript Execution
    
    private func executeJS(_ script: String) {
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ JS Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func callJSCallback(_ callback: String?, result: Any) {
        guard let callback = callback else { return }
        
        var resultString = ""
        
        if let dict = result as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: dict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            resultString = jsonString
        } else if let array = result as? [[String: Any]],
                  let jsonData = try? JSONSerialization.data(withJSONObject: array),
                  let jsonString = String(data: jsonData, encoding: .utf8) {
            resultString = jsonString
            executeJS("window._h5gg_results = \(jsonString);")
            return
        } else {
            resultString = "\(result)"
        }
        
        executeJS("\(callback)(\(resultString));")
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        guard let webView = webView else { return }
        
        let handlers = [
            "searchNumber", "editAll", "setValue", "getResults",
            "getResultsCount", "clearResults", "searchNearby",
            "attachProcess", "detachProcess", "isAttached", "getProcessInfo"
        ]
        
        for handler in handlers {
            webView.configuration.userContentController.removeScriptMessageHandler(forName: handler)
        }
    }
}
