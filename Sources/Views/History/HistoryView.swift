import SwiftUI

/// Экран истории просмотров Киного (прогресс просмотра фильмов/сериалов)
public struct HistoryView: View {
    @StateObject private var storage = StorageService.shared
    @StateObject private var service = MovieService()
    
    @State private var activePlayingMovie: Movie? = nil
    @State private var activePlayingSource: VideoSource? = nil
    @State private var showPlayer = false
    @State private var showClearAlert = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                if storage.history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 54))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("История просмотров пуста")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Когда вы начнете смотреть видео, здесь появится прогресс просмотра")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(storage.history) { progress in
                                // Находим фильм в базе данных
                                if let movie = service.movies.first(where: { $0.id == progress.movieId }) {
                                    HStack(spacing: 16) {
                                        // Постер с оверлеем прогресса
                                        ZStack(alignment: .bottom) {
                                            AsyncImage(url: URL(string: progress.posterURL)) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 80, height: 110)
                                                        .cornerRadius(Theme.Radius.small)
                                                } else {
                                                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                                                        .fill(Theme.Colors.surfaceSecondary)
                                                        .frame(width: 80, height: 110)
                                                }
                                            }
                                            
                                            // Линия прогресса
                                            ProgressView(value: progress.progressPercent, total: 1.0)
                                                .progressViewStyle(LinearProgressViewStyle(tint: Theme.Colors.accent))
                                                .frame(width: 80)
                                        }
                                        .neonGlowBorder(radius: Theme.Radius.small)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(progress.movieTitle)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Theme.Colors.textPrimary)
                                                .lineLimit(1)
                                            
                                            if let src = progress.lastPlayedSource {
                                                Text("\(src.voiceActing) • \(src.quality)")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(Theme.Colors.textSecondary)
                                            }
                                            
                                            Text("Просмотрено: \(Int(progress.progressPercent * 100))%")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Theme.Colors.accent)
                                            
                                            Text("Остановились на \(formatSeconds(progress.position))")
                                                .font(.system(size: 11, weight: .light))
                                                .foregroundColor(Theme.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Кнопка продолжить просмотр (сразу запускает плеер)
                                        Button(action: {
                                            activePlayingMovie = movie
                                            // Берем ранее выбранный источник или первый доступный
                                            activePlayingSource = progress.lastPlayedSource ?? movie.videoSources.first
                                            if activePlayingSource != nil {
                                                showPlayer = true
                                            }
                                        }) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.black)
                                                .padding(12)
                                                .background(Theme.Colors.accent)
                                                .clipShape(Circle())
                                                .shadow(color: Theme.Colors.accent.opacity(0.4), radius: 6)
                                        }
                                    }
                                    .padding(12)
                                    .background(Theme.Colors.surface)
                                    .cornerRadius(Theme.Radius.card)
                                    .neonGlowBorder(radius: Theme.Radius.card)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                storage.removeFromHistory(movieId: progress.movieId)
                                            }
                                        } label: {
                                            Label("Удалить", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("История просмотров")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !storage.history.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showClearAlert = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Очистить историю?", isPresented: $showClearAlert) {
                Button("Очистить", role: .destructive) {
                    withAnimation {
                        storage.clearHistory()
                    }
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Это действие удалит весь прогресс просмотра фильмов и сериалов.")
            }
            .fullScreenCover(isPresented: $showPlayer) {
                if let movie = activePlayingMovie, let sourceBinding = Binding($activePlayingSource) {
                    AdvancedVideoPlayer(
                        movie: movie,
                        selectedSource: sourceBinding,
                        onDismiss: { showPlayer = false }
                    )
                }
            }
        }
    }
    
    private func formatSeconds(_ seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}
