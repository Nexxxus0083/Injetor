//
//  AppDelegate.swift
//  MemoryInjector
//
//  Delegate principal do aplicativo com auto-attach ao Free Fire
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var floatingWindow: FloatingWindow?
    var autoAttachTimer: Timer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Criar janela principal (invisível)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.backgroundColor = .clear
        window?.makeKeyAndVisible()
        
        // Criar janela flutuante
        setupFloatingWindow()
        
        // Iniciar detecção automática do Free Fire
        startAutoAttach()
        
        print("✅ Memory Injector started successfully")
        print("🎮 Auto-attach to Free Fire enabled")
        
        return true
    }
    
    private func setupFloatingWindow() {
        floatingWindow = FloatingWindow(frame: UIScreen.main.bounds)
        floatingWindow?.isHidden = false
    }
    
    private func startAutoAttach() {
        // Tentar conectar imediatamente
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.tryAttachToFreeFire()
        }
        
        // Verificar periodicamente se o Free Fire está rodando
        autoAttachTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.tryAttachToFreeFire()
        }
    }
    
    private func tryAttachToFreeFire() {
        let memoryEngine = MemoryEngine.shared
        
        // Se já está conectado, não fazer nada
        if memoryEngine.isAttached() {
            return
        }
        
        // Tentar conectar ao Free Fire
        let processNames = [
            "com.dts.freefire",
            "FreeFire",
            "Free Fire",
            "freefire"
        ]
        
        for processName in processNames {
            if memoryEngine.attachProcess(processName) {
                print("✅ Auto-attached to Free Fire: \(processName)")
                showNotification(title: "Memory Injector", message: "Conectado ao Free Fire!")
                break
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        // Mostrar notificação local (opcional)
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let rootVC = self.window?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Manter o app ativo em background
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Manter serviços ativos
        print("📱 App entered background - maintaining connection")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Restaurar estado
        print("📱 App entering foreground")
        tryAttachToFreeFire()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Reativar funcionalidades
        tryAttachToFreeFire()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Limpar recursos
        autoAttachTimer?.invalidate()
        MemoryEngine.shared.detachProcess()
        print("👋 Memory Injector terminated")
    }
}
