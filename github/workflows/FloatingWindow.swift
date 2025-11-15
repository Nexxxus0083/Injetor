//
//  FloatingWindow.swift
//  MemoryInjector
//
//  Janela flutuante que sobrepõe outros aplicativos
//

import UIKit

class FloatingWindow: UIWindow {
    private var floatingButton: FloatingButton?
    private var menuViewController: WebViewController?
    private var isMenuVisible = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Configurar janela para ficar sempre no topo
        windowLevel = .alert + 1
        backgroundColor = .clear
        
        // Criar botão flutuante
        createFloatingButton()
        
        // Criar view controller do menu
        menuViewController = WebViewController()
        menuViewController?.view.isHidden = true
        
        if let menuView = menuViewController?.view {
            addSubview(menuView)
            menuView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                menuView.centerXAnchor.constraint(equalTo: centerXAnchor),
                menuView.centerYAnchor.constraint(equalTo: centerYAnchor),
                menuView.widthAnchor.constraint(equalToConstant: 360),
                menuView.heightAnchor.constraint(equalToConstant: 320)
            ])
        }
        
        makeKeyAndVisible()
    }
    
    private func createFloatingButton() {
        floatingButton = FloatingButton(frame: CGRect(x: 20, y: 100, width: 60, height: 60))
        floatingButton?.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
        
        if let button = floatingButton {
            addSubview(button)
        }
    }
    
    @objc private func toggleMenu() {
        isMenuVisible.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.menuViewController?.view.isHidden = !self.isMenuVisible
            self.menuViewController?.view.alpha = self.isMenuVisible ? 1.0 : 0.0
        }
    }
    
    func hideMenu() {
        isMenuVisible = false
        menuViewController?.view.isHidden = true
    }
    
    func showMenu() {
        isMenuVisible = true
        menuViewController?.view.isHidden = false
    }
}

// MARK: - Floating Button

class FloatingButton: UIButton {
    private var panGesture: UIPanGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Estilo do botão
        backgroundColor = UIColor(red: 0.73, green: 0.03, blue: 0.11, alpha: 0.9)
        layer.cornerRadius = 30
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 4
        
        // Ícone
        setTitle("🎮", for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 30)
        
        // Gesture para arrastar
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let window = superview else { return }
        
        let translation = gesture.translation(in: window)
        
        if gesture.state == .changed {
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: window)
        } else if gesture.state == .ended {
            // Snap to edges
            let screenWidth = window.bounds.width
            let screenHeight = window.bounds.height
            
            var newX = center.x
            var newY = center.y
            
            // Limitar aos bounds da tela
            newX = max(30, min(newX, screenWidth - 30))
            newY = max(50, min(newY, screenHeight - 50))
            
            // Snap para a borda mais próxima (esquerda ou direita)
            if newX < screenWidth / 2 {
                newX = 30
            } else {
                newX = screenWidth - 30
            }
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                self.center = CGPoint(x: newX, y: newY)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }
    }
}
