import SwiftUI

/// Дизайн-система приложения Киного (Стиль: Premium Neon Glassmorphism)
public enum Theme {
    
    public enum Colors {
        /// Глубокий черный фон кинозала
        public static let background = Color(red: 0.03, green: 0.03, blue: 0.04)
        
        /// Темно-серая поверхность для карточек и панелей
        public static let surface = Color(red: 0.08, green: 0.08, blue: 0.10)
        
        /// Светлая поверхность для контрастных элементов
        public static let surfaceSecondary = Color(red: 0.14, green: 0.14, blue: 0.17)
        
        /// Основной фирменный неоново-оранжевый акцент
        public static let accent = Color(red: 1.00, green: 0.42, blue: 0.00) // #FF6C00
        
        /// Градиент для кнопок воспроизведения
        public static let accentGradient = Gradient(colors: [
            Color(red: 1.00, green: 0.42, blue: 0.00), // Оранжевый
            Color(red: 1.00, green: 0.23, blue: 0.19)  // Красный
        ])
        
        /// Яркий зеленый цвет для высоких рейтингов
        public static let ratingHigh = Color(red: 0.00, green: 0.90, blue: 0.46) // #00E676
        
        /// Желтый цвет для средних рейтингов
        public static let ratingMedium = Color(red: 1.00, green: 0.80, blue: 0.00) // #FFCC00
        
        /// Серый цвет для низких рейтингов
        public static let ratingLow = Color(red: 0.60, green: 0.60, blue: 0.60)
        
        /// Основной белый текст
        public static let textPrimary = Color.white
        
        /// Вторичный приглушенный серый текст
        public static let textSecondary = Color(red: 0.55, green: 0.55, blue: 0.60) // #8E8E93
        
        /// Цвет границ по умолчанию
        public static let border = Color(red: 0.18, green: 0.18, blue: 0.22)
        
        /// Цвет неоновой светящейся границы
        public static let neonBorder = Color(red: 1.00, green: 0.42, blue: 0.00, opacity: 0.3)
    }
    
    public enum Radius {
        public static let small: CGFloat = 8
        public static let card: CGFloat = 16
        public static let button: CGFloat = 14
        public static let large: CGFloat = 28
    }
    
    public enum Animations {
        /// Динамичная пружинная анимация для интерактивных элементов
        public static let interactiveSpring = Animation.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0)
        
        /// Плавное растворение для переходов
        public static let smoothFade = Animation.easeInOut(duration: 0.25)
    }
}

// MARK: - View Modifiers

public struct GlassmorphicModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear,
                                Theme.Colors.accent.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

public struct NeonGlowBorderModifier: ViewModifier {
    var cornerRadius: CGFloat
    var isGlowing: Bool
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isGlowing ? Theme.Colors.accent.opacity(0.6) : Theme.Colors.border,
                        lineWidth: isGlowing ? 1.5 : 1.0
                    )
                    .shadow(
                        color: isGlowing ? Theme.Colors.accent.opacity(0.4) : Color.clear,
                        radius: isGlowing ? 8 : 0,
                        x: 0,
                        y: 0
                    )
            )
    }
}

public extension View {
    /// Применяет эффект Glassmorphism с размытием заднего плана и тонкой полупрозрачной границей
    func glassBackground(radius: CGFloat = Theme.Radius.card) -> some View {
        self.modifier(GlassmorphicModifier(cornerRadius: radius))
    }
    
    /// Применяет тонкую неоновую светящуюся рамку
    func neonGlowBorder(radius: CGFloat = Theme.Radius.card, isGlowing: Bool = false) -> some View {
        self.modifier(NeonGlowBorderModifier(cornerRadius: radius, isGlowing: isGlowing))
    }
}

/// Элегантная пружинная анимация для кнопок при нажатии
public struct ScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(Theme.Animations.interactiveSpring, value: configuration.isPressed)
    }
}
