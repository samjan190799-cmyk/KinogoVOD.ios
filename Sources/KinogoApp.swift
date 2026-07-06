import SwiftUI

// Точка входа в iOS-приложение Киного
@main
struct KinogoApp: App {
    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .preferredColorScheme(.dark) // Принудительно устанавливаем темную тему для атмосферы кинозала
        }
    }
}
