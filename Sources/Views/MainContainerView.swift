import SwiftUI

/// Корневой контейнер с кастомным плавающим TabBar в стиле Glassmorphism & Neon Glow
public struct MainContainerView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab: Int, CaseIterable {
        case home
        case search
        case bookmarks
        case history
        
        var icon: String {
            switch self {
            case .home: return "popcorn.fill"
            case .search: return "magnifyingglass"
            case .bookmarks: return "bookmark.fill"
            case .history: return "clock.fill"
            }
        }
        
        var title: String {
            switch self {
            case .home: return "Главная"
            case .search: return "Поиск"
            case .bookmarks: return "Закладки"
            case .history: return "История"
            }
        }
    }
    
    public init() {
        // Отключаем стандартный TabBar
        UITabBar.appearance().isHidden = true
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Экраны под вкладками
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                
                SearchView()
                    .tag(Tab.search)
                
                BookmarksView()
                    .tag(Tab.bookmarks)
                
                HistoryView()
                    .tag(Tab.history)
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Кастомный плавающий TabBar
            customTabBar()
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private func customTabBar() -> some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                Spacer()
                
                Button(action: {
                    withAnimation(Theme.Animations.interactiveSpring) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? Theme.Colors.accent : Theme.Colors.textSecondary)
                            .shadow(color: selectedTab == tab ? Theme.Colors.accent.opacity(0.4) : Color.clear, radius: 6)
                        
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : Theme.Colors.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .neonGlowBorder(radius: 24, isGlowing: true) // Светящаяся оранжевая рамка TabBar
    }
}
