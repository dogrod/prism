//
//  SceneDelegate.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // Create the window
        let window = UIWindow(windowScene: windowScene)
        
        // Create services
        let ocrService = VisionOCRService()
        let llmService = OpenAILLMService()
        
        // Create ViewModel and ViewController
        let viewModel = CaptureViewModel(ocrService: ocrService, llmService: llmService)
        let captureVC = CaptureViewController(viewModel: viewModel)
        
        // Embed in Navigation Controller
        let navigationController = UINavigationController(rootViewController: captureVC)
        navigationController.navigationBar.prefersLargeTitles = true
        
        // Configure and present window
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is released by the system.
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene becomes active.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will resign active state.
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from background to foreground.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save Core Data changes when entering background
        (UIApplication.shared.delegate as? AppDelegate)?.persistenceController.container.viewContext.saveIfNeeded()
    }
}

// MARK: - NSManagedObjectContext Extension
extension NSManagedObjectContext {
    func saveIfNeeded() {
        if hasChanges {
            do {
                try save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
