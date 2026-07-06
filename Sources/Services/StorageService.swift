import Foundation

/// Сервис локального хранения для закладок и истории просмотров
@MainActor
public final class StorageService: ObservableObject {
    
    public static let shared = StorageService()
    
    private let bookmarksKey = "kinogo_bookmarks_v1"
    private let historyKey = "kinogo_history_v1"
    
    @Published public private(set) var bookmarks: [String] = [] // Массив ID фильмов
    @Published public private(set) var history: [PlaybackProgress] = []
    
    private init() {
        loadBookmarks()
        loadHistory()
    }
    
    // MARK: - Bookmarks (Избранное)
    
    private func loadBookmarks() {
        if let data = UserDefaults.standard.array(forKey: bookmarksKey) as? [String] {
            self.bookmarks = data
        }
    }
    
    private func saveBookmarks() {
        UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
    }
    
    public func isBookmarked(movieId: String) -> Bool {
        bookmarks.contains(movieId)
    }
    
    public func toggleBookmark(movieId: String) {
        if isBookmarked(movieId: movieId) {
            bookmarks.removeAll { $0 == movieId }
        } else {
            bookmarks.append(movieId)
        }
        saveBookmarks()
    }
    
    public func removeBookmark(movieId: String) {
        bookmarks.removeAll { $0 == movieId }
        saveBookmarks()
    }
    
    // MARK: - Playback History (История просмотров)
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([PlaybackProgress].self, from: data)
            self.history = decoded.sorted(by: { $0.lastUpdated > $1.lastUpdated })
        } catch {
            print("Ошибка загрузки истории просмотров: \(error)")
        }
    }
    
    private func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(history)
            UserDefaults.standard.set(encoded, forKey: historyKey)
        } catch {
            print("Ошибка сохранения истории просмотров: \(error)")
        }
    }
    
    /// Сохраняет или обновляет прогресс просмотра фильма
    public func saveProgress(
        movieId: String,
        movieTitle: String,
        posterURL: String,
        source: VideoSource?,
        position: Double,
        duration: Double
    ) {
        // Если просмотрено больше 95% фильма, можно считать его полностью просмотренным и удалить/не сохранять большой прогресс
        // Но для удобства оставим сохранение, просто обновив
        
        let newProgress = PlaybackProgress(
            movieId: movieId,
            movieTitle: movieTitle,
            posterURL: posterURL,
            lastPlayedSource: source,
            position: position,
            duration: duration,
            lastUpdated: Date()
        )
        
        // Удаляем старую запись для этого фильма, если она есть
        history.removeAll { $0.movieId == movieId }
        
        // Вставляем новую запись в начало
        history.insert(newProgress, at: 0)
        
        // Ограничиваем историю, например, 50 записями
        if history.count > 50 {
            history = Array(history.prefix(50))
        }
        
        saveHistory()
    }
    
    /// Возвращает сохраненный прогресс воспроизведения для конкретного фильма
    public func getProgress(movieId: String) -> PlaybackProgress? {
        history.first { $0.movieId == movieId }
    }
    
    /// Удаляет фильм из истории
    public func removeFromHistory(movieId: String) {
        history.removeAll { $0.movieId == movieId }
        saveHistory()
    }
    
    /// Полностью очищает историю
    public func clearHistory() {
        history.removeAll()
        saveHistory()
    }
}
