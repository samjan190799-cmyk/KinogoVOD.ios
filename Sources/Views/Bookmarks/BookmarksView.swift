import SwiftUI

/// Экран закладок (Избранного) в приложении Киного
public struct BookmarksView: View {
    @StateObject private var storage = StorageService.shared
    @StateObject private var service = MovieService()
    
    // Сетка с 2 колонками
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                let bookmarkedMovies = service.movies.filter { storage.bookmarks.contains($0.id) }
                
                if bookmarkedMovies.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 54))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("У вас пока нет закладок")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Добавляйте фильмы и сериалы в избранное, чтобы посмотреть их позже")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(bookmarkedMovies) { movie in
                                NavigationLink(value: movie) {
                                    ZStack(alignment: .topTrailing) {
                                        // Карточка фильма
                                        BookmarkCardView(movie: movie)
                                        
                                        // Кнопка быстрого удаления
                                        Button(action: {
                                            withAnimation(Theme.Animations.interactiveSpring) {
                                                storage.removeBookmark(movieId: movie.id)
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                                .padding(8)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Мои закладки")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
    }
}

// MARK: - Карточка для Избранного

struct BookmarkCardView: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: movie.posterURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 220)
                        .cornerRadius(Theme.Radius.card)
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(Theme.Colors.surface)
                        .frame(height: 220)
                        .overlay(ProgressView().tint(Theme.Colors.accent))
                }
            }
            .neonGlowBorder(radius: Theme.Radius.card)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    Text(String(movie.year))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Theme.Colors.accent)
                            .font(.system(size: 9))
                        Text(String(format: "%.1f", movie.ratingKp))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
