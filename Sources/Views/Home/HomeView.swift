import SwiftUI

/// Главный экран каталога Киного с неоновым дизайном и категориями
public struct HomeView: View {
    @StateObject private var service = MovieService()
    @State private var selectedCategory: String = "Все" // Все, Фильмы, Сериалы
    @State private var selectedGenre: String = "Все"
    
    private let categories = ["Все", "Фильмы", "Сериалы"]
    
    // Жанры, выгруженные из базы данных
    private var genresList: [String] {
        var genres = ["Все"]
        let allGenres = service.movies.flatMap { $0.genres }
        genres.append(contentsOf: allGenres.unique())
        return genres
    }
    
    public init() {
        // Прозрачная плашка навигации для красивого наложения баннера
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                // Легкое неоновое оранжевое свечение на фоне (Ambient Light)
                RadialGradient(
                    colors: [Theme.Colors.accent.opacity(0.12), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // 1. Верхний Логотип и Профиль
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("КИНО")
                                        .font(.system(size: 24, weight: .black))
                                        .foregroundColor(.white)
                                    Text("ГО")
                                        .font(.system(size: 24, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.Colors.accent)
                                        .cornerRadius(6)
                                        .shadow(color: Theme.Colors.accent.opacity(0.5), radius: 8)
                                }
                                
                                Text("Смотрите новинки с samkino.kinogo.luxury")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Кнопка профиля с неоновой рамкой
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Theme.Colors.surface)
                                .clipShape(Circle())
                                .neonGlowBorder(radius: 20, isGlowing: false)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // 2. Селектор Категорий (Табы в стиле Glassmorphism)
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    withAnimation(Theme.Animations.interactiveSpring) {
                                        selectedCategory = cat
                                    }
                                }) {
                                    Text(cat)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(selectedCategory == cat ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedCategory == cat ? Theme.Colors.accent : Theme.Colors.surface)
                                        .cornerRadius(10)
                                        .neonGlowBorder(radius: 10, isGlowing: selectedCategory == cat)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 3. Большой Промо-Баннер (Featured Movie)
                        if let featured = service.movies.first(where: { $0.isFeatured }) {
                            NavigationLink(value: featured) {
                                HeroBannerView(movie: featured)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                        }
                        
                        // 4. Селектор Жанров (Горизонтальные теги)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Жанры")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(genresList, id: \.self) { genre in
                                        Button(action: {
                                            withAnimation(Theme.Animations.interactiveSpring) {
                                                selectedGenre = genre
                                            }
                                        }) {
                                            Text(genre)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(selectedGenre == genre ? Theme.Colors.accent : Theme.Colors.textSecondary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Theme.Colors.surface)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedGenre == genre ? Theme.Colors.accent : Theme.Colors.border, lineWidth: 1.2)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // 5. Разделы с фильмами (Карусели)
                        VStack(spacing: 28) {
                            let filtered = getFilteredMovies()
                            
                            if filtered.isEmpty {
                                VStack {
                                    Image(systemName: "film")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                        .padding(.bottom, 8)
                                    Text("Нет подходящего контента")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                            } else {
                                // А) Горячие Новинки (2024-2026)
                                let newMovies = filtered.filter { $0.year >= 2024 }
                                if !newMovies.isEmpty {
                                    movieCarousel(title: "Горячие новинки", movies: newMovies)
                                }
                                
                                // Б) Лучшие по рейтингу
                                let topRated = filtered.sorted(by: { $0.ratingKp > $1.ratingKp })
                                if !topRated.isEmpty {
                                    movieCarousel(title: "Высокий рейтинг", movies: topRated)
                                }
                                
                                // В) Все отфильтрованные фильмы
                                movieCarousel(title: "Рекомендуем", movies: filtered)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
    }
    
    // MARK: - Helper Logic & Views
    
    private func getFilteredMovies() -> [Movie] {
        var result = service.movies
        
        // Фильтр по категории
        if selectedCategory == "Фильмы" {
            result = result.filter { !$0.isSeries }
        } else if selectedCategory == "Сериалы" {
            result = result.filter { $0.isSeries }
        }
        
        // Фильтр по жанру
        if selectedGenre != "Все" {
            result = result.filter { $0.genres.contains(selectedGenre) }
        }
        
        return result
    }
    
    @ViewBuilder
    private func movieCarousel(title: String, movies: [Movie]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        NavigationLink(value: movie) {
                            MovieCardView(movie: movie)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Subviews

struct HeroBannerView: View {
    let movie: Movie
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Изображение баннера
            AsyncImage(url: URL(string: movie.bannerURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .frame(height: 220)
                        .overlay(ProgressView().tint(Theme.Colors.accent))
                }
            }
            
            // Затемнение
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Детали поверх баннера
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("В тренде")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.accent)
                        .cornerRadius(4)
                        .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 4)
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Theme.Colors.ratingHigh)
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", movie.ratingKp))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(4)
                }
                
                Text(movie.title)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(movie.genres.joined(separator: ", ") + " • " + String(movie.year))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(16)
        }
        .frame(height: 220)
        .cornerRadius(Theme.Radius.card)
        .neonGlowBorder(radius: Theme.Radius.card, isGlowing: true)
    }
}

struct MovieCardView: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                // Постер
                AsyncImage(url: URL(string: movie.posterURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 135, height: 195)
                            .cornerRadius(Theme.Radius.card)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .fill(Theme.Colors.surface)
                            .frame(width: 135, height: 195)
                            .overlay(ProgressView().tint(Theme.Colors.accent))
                    }
                }
                
                // Плашка рейтинга Кинопоиска в верхнем углу
                Text(String(format: "%.1f", movie.ratingKp))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(movie.ratingKp >= 8.0 ? Theme.Colors.ratingHigh : Theme.Colors.ratingMedium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(6)
                    .padding(8)
            }
            .neonGlowBorder(radius: Theme.Radius.card, isGlowing: false)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text("\(String(movie.year)) • \(movie.isSeries ? "Сериал" : "Фильм")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
        .frame(width: 135)
    }
}
