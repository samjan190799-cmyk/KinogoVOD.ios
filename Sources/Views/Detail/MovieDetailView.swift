import SwiftUI

/// Эстетичный детальный экран фильма в неоновом стиле с размытием и выбором озвучки/качества
public struct MovieDetailView: View {
    let movie: Movie
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @StateObject private var service = MovieService()
    
    @State private var selectedSource: VideoSource
    @State private var showPlayer = false
    
    public init(movie: Movie) {
        self.movie = movie
        // Инициализируем выбранный источник видео по умолчанию (первый доступный)
        if let firstSource = movie.videoSources.first {
            self._selectedSource = State(initialValue: firstSource)
        } else {
            self._selectedSource = State(initialValue: VideoSource(voiceActing: "Неизвестно", quality: "720p", videoURL: ""))
        }
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                // 1. Постер с эффектом параллакса и размытием заднего фона
                ZStack(alignment: .bottomLeading) {
                    // Задний фон (размытый постер фильма)
                    AsyncImage(url: URL(string: movie.posterURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 520)
                                .blur(radius: 20)
                                .opacity(0.4)
                        } else {
                            Rectangle()
                                .fill(Theme.Colors.background)
                                .frame(height: 520)
                        }
                    }
                    .ignoresSafeArea()
                    
                    // Передний постер с неоновым свечением
                    VStack(spacing: 0) {
                        Spacer().frame(height: 80)
                        
                        HStack(alignment: .bottom, spacing: 20) {
                            AsyncImage(url: URL(string: movie.posterURL)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 150, height: 220)
                                        .cornerRadius(Theme.Radius.card)
                                        .neonGlowBorder(radius: Theme.Radius.card, isGlowing: true)
                                } else {
                                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                                        .fill(Theme.Colors.surface)
                                        .frame(width: 150, height: 220)
                                        .overlay(ProgressView().tint(Theme.Colors.accent))
                                        .neonGlowBorder(radius: Theme.Radius.card)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(movie.title)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .lineLimit(2)
                                
                                Text(movie.originalTitle)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .lineLimit(2)
                                
                                // Метки Год / Длительность / Страна
                                HStack(spacing: 8) {
                                    Text(String(movie.year))
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.Colors.surfaceSecondary)
                                        .cornerRadius(6)
                                    
                                    Text(movie.duration)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                .padding(.top, 4)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Затемнение к низу
                    LinearGradient(
                        colors: [.clear, Theme.Colors.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 180)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 2. Блок рейтингов и кнопки "В закладки"
                    HStack(spacing: 16) {
                        // Рейтинг Кинопоиск
                        ratingBadge(title: "КП", rating: movie.ratingKp)
                        
                        // Рейтинг IMDb
                        ratingBadge(title: "IMDb", rating: movie.ratingImdb)
                        
                        Spacer()
                        
                        // Кнопка Избранного
                        Button(action: {
                            withAnimation(Theme.Animations.interactiveSpring) {
                                storage.toggleBookmark(movieId: movie.id)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: storage.isBookmarked(movieId: movie.id) ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(storage.isBookmarked(movieId: movie.id) ? .black : Theme.Colors.accent)
                                Text(storage.isBookmarked(movieId: movie.id) ? "В закладках" : "Буду смотреть")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(storage.isBookmarked(movieId: movie.id) ? .black : .white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(storage.isBookmarked(movieId: movie.id) ? Theme.Colors.accent : Theme.Colors.surface)
                            .cornerRadius(10)
                            .neonGlowBorder(radius: 10, isGlowing: storage.isBookmarked(movieId: movie.id))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 3. Кнопка "Смотреть" / "Продолжить"
                    let progress = storage.getProgress(movieId: movie.id)
                    Button(action: {
                        showPlayer = true
                    }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 10) {
                                Image(systemName: progress != nil ? "arrow.clockwise.circle.fill" : "play.fill")
                                    .font(.system(size: 20))
                                Text(progress != nil ? "Продолжить просмотр" : "Смотреть фильм")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            
                            if let progress = progress {
                                Text("Остановились на \(formatSeconds(progress.position)) из \(formatSeconds(progress.duration))")
                                    .font(.system(size: 11, weight: .light))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                // Полоса прогресса под кнопкой
                                ProgressView(value: progress.progressPercent, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                    .padding(.horizontal, 40)
                                    .padding(.top, 2)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, progress != nil ? 12 : 16)
                        .background(
                            LinearGradient(
                                gradient: Theme.Colors.accentGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(Theme.Radius.button)
                        .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // 4. Селекторы озвучки и качества
                    if !movie.videoSources.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Выбор дорожки и качества")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            // Карусель озвучек
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(movie.videoSources.map({ $0.voiceActing }).unique(), id: \.self) { voice in
                                        Button(action: {
                                            if let firstSrc = movie.videoSources.first(where: { $0.voiceActing == voice }) {
                                                selectedSource = firstSrc
                                            }
                                        }) {
                                            Text(voice)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(selectedSource.voiceActing == voice ? .black : .white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(selectedSource.voiceActing == voice ? Theme.Colors.accent : Theme.Colors.surface)
                                                .cornerRadius(8)
                                                .neonGlowBorder(radius: 8, isGlowing: selectedSource.voiceActing == voice)
                                        }
                                    }
                                }
                            }
                            
                            // Карусель качества для выбранной озвучки
                            HStack(spacing: 10) {
                                ForEach(movie.videoSources.filter({ $0.voiceActing == selectedSource.voiceActing }), id: \.id) { src in
                                    Button(action: { selectedSource = src }) {
                                        Text(src.quality)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(selectedSource.quality == src.quality ? Theme.Colors.accent : Theme.Colors.textSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(Theme.Colors.surfaceSecondary)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(selectedSource.quality == src.quality ? Theme.Colors.accent : Color.clear, lineWidth: 1.5)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 5. Описание сюжета
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Сюжет")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text(movie.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineSpacing(5)
                    }
                    .padding(.horizontal, 20)
                    
                    // 6. Подробная информация
                    VStack(alignment: .leading, spacing: 14) {
                        Text("О фильме")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Group {
                            detailInfoRow(title: "Режиссер", value: movie.director)
                            detailInfoRow(title: "В главных ролях", value: movie.actors.joined(separator: ", "))
                            detailInfoRow(title: "Жанры", value: movie.genres.joined(separator: ", "))
                            detailInfoRow(title: "Страна", value: movie.countries.joined(separator: ", "))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.surface)
                    .cornerRadius(Theme.Radius.card)
                    .padding(.horizontal, 20)
                    
                    // 7. Похожие фильмы
                    let similar = service.movies.filter { $0.id != movie.id && !$0.genres.intersection(movie.genres).isEmpty }
                    if !similar.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Похожие фильмы и сериалы")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.Colors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(similar) { simMovie in
                                        NavigationLink(value: simMovie) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                AsyncImage(url: URL(string: simMovie.posterURL)) { phase in
                                                    if let image = phase.image {
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 110, height: 160)
                                                            .cornerRadius(Theme.Radius.card)
                                                    } else {
                                                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                                                            .fill(Theme.Colors.surfaceSecondary)
                                                            .frame(width: 110, height: 160)
                                                    }
                                                }
                                                .neonGlowBorder(radius: Theme.Radius.card)
                                                
                                                Text(simMovie.title)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(Theme.Colors.textPrimary)
                                                    .lineLimit(1)
                                                    .frame(width: 110, alignment: .leading)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .neonGlowBorder(radius: 20)
                }
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            AdvancedVideoPlayer(
                movie: movie,
                selectedSource: $selectedSource,
                onDismiss: { showPlayer = false }
            )
        }
    }
    
    // MARK: - Helper UI Components
    
    private func ratingBadge(title: String, rating: Double) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.Colors.textSecondary)
            
            Text(String(format: "%.1f", rating))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ratingColor(rating))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.Colors.surface)
        .cornerRadius(6)
        .neonGlowBorder(radius: 6, isGlowing: rating >= 8.0)
    }
    
    private func ratingColor(_ rating: Double) -> Color {
        if rating >= 8.0 {
            return Theme.Colors.ratingHigh
        } else if rating >= 6.0 {
            return Theme.Colors.ratingMedium
        } else {
            return Theme.Colors.ratingLow
        }
    }
    
    private func detailInfoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 90, alignment: .leading)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
        }
    }
    
    private func formatSeconds(_ seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return "\(hours) ч. \(mins) мин."
        } else {
            return "\(mins):\(String(format: "%02d", secs))"
        }
    }
}

// MARK: - Helper Extensions for Arrays of Strings

extension Array where Element == String {
    func intersection(_ other: [String]) -> Set<String> {
        let setA = Set(self)
        let setB = Set(other)
        return setA.intersection(setB)
    }
}
