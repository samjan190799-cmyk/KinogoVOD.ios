import Foundation

/// Модель жанра фильма/сериала
public struct Genre: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// Модель видео-источника (для выбора озвучки и качества на Киного)
public struct VideoSource: Codable, Identifiable, Hashable, Sendable {
    public var id: String { voiceActing + "_" + quality }
    public let voiceActing: String  // Например, "Дубляж", "HDRezka Studio", "LostFilm"
    public let quality: String      // Например, "1080p", "720p", "480p"
    public let videoURL: String     // Ссылка на HLS (.m3u8) или MP4 файл
    
    public init(voiceActing: String, quality: String, videoURL: String) {
        self.voiceActing = voiceActing
        self.quality = quality
        self.videoURL = videoURL
    }
}

/// Основная модель контента (Фильм или Сериал)
public struct Movie: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String           // Название на русском
    public let originalTitle: String   // Оригинальное название
    public let description: String     // Описание сюжета
    public let ratingKp: Double        // Рейтинг Кинопоиск (например, 7.8)
    public let ratingImdb: Double      // Рейтинг IMDb (например, 8.1)
    public let year: Int               // Год выпуска
    public let duration: String        // Продолжительность (например, "124 мин." или "8 серий")
    public let genres: [String]        // Жанры
    public let countries: [String]     // Страны производства
    public let director: String        // Режиссер
    public let actors: [String]        // В главных ролях
    public let posterURL: String       // Ссылка на постер
    public let bannerURL: String       // Ссылка на баннер для главного экрана
    public var isSeries: Bool          // Флаг сериала
    public let isFeatured: Bool        // Показывать на главном баннере
    public let videoSources: [VideoSource] // Доступные озвучки и разрешения
    
    public init(
        id: String,
        title: String,
        originalTitle: String,
        description: String,
        ratingKp: Double,
        ratingImdb: Double,
        year: Int,
        duration: String,
        genres: [String],
        countries: [String],
        director: String,
        actors: [String],
        posterURL: String,
        bannerURL: String,
        isSeries: Bool = false,
        isFeatured: Bool = false,
        videoSources: [VideoSource] = []
    ) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.description = description
        self.ratingKp = ratingKp
        self.ratingImdb = ratingImdb
        self.year = year
        self.duration = duration
        self.genres = genres
        self.countries = countries
        self.director = director
        self.actors = actors
        self.posterURL = posterURL
        self.bannerURL = bannerURL
        self.isSeries = isSeries
        self.isFeatured = isFeatured
        self.videoSources = videoSources
    }
}

/// Модель прогресса воспроизведения (для истории просмотров)
public struct PlaybackProgress: Codable, Identifiable, Hashable, Sendable {
    public var id: String { movieId }
    public let movieId: String
    public let movieTitle: String
    public let posterURL: String
    public let lastPlayedSource: VideoSource?
    public let position: Double        // Секунда, на которой остановился просмотр
    public let duration: Double        // Общая длительность видео в секундах
    public let lastUpdated: Date
    
    public var progressPercent: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, position / duration)
    }
    
    public init(
        movieId: String,
        movieTitle: String,
        posterURL: String,
        lastPlayedSource: VideoSource?,
        position: Double,
        duration: Double,
        lastUpdated: Date = Date()
    ) {
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.posterURL = posterURL
        self.lastPlayedSource = lastPlayedSource
        self.position = position
        self.duration = duration
        self.lastUpdated = lastUpdated
    }
}
