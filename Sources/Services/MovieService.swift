import Foundation

/// Сервис каталога фильмов и сериалов (на основе контента samkino.kinogo.luxury)
@MainActor
public final class MovieService: ObservableObject {
    
    @Published public private(set) var movies: [Movie] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    
    public init() {
        loadLocalDatabase()
    }
    
    /// Загрузка базы данных фильмов и сериалов
    public func loadLocalDatabase() {
        self.movies = [
            // 1. Мандалорец и Грогу (Фильм, 2026) - Featured
            Movie(
                id: "mandalorian_grogu_2026",
                title: "Мандалорец и Грогу",
                originalTitle: "The Mandalorian & Grogu",
                description: "Продолжение приключений одинокого мандалорца-наемника Дина Джарина и его маленького чувствительного к Силе подопечного Грогу. Вместе они отправляются в новое опасное путешествие по галактике, сталкиваясь с остатками Империи и новыми синдикатами, чтобы защитить свое будущее.",
                ratingKp: 8.2,
                ratingImdb: 8.4,
                year: 2026,
                duration: "135 мин.",
                genres: ["Фантастика", "Боевик", "Приключения"],
                countries: ["США"],
                director: "Джон Фавро",
                actors: ["Педро Паскаль", "Стивен Блум", "Ди Брэдли Бейкер"],
                posterURL: "https://images.unsplash.com/photo-1593085512500-5d55148d6f0d?auto=format&fit=crop&q=80&w=600", // Заглушка яркого постера
                bannerURL: "https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&q=80&w=1200", // Широкий баннер космоса
                isSeries: false,
                isFeatured: true,
                videoSources: [
                    VideoSource(
                        voiceActing: "Дубляж (Red Head Sound)",
                        quality: "1080p",
                        videoURL: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
                    ),
                    VideoSource(
                        voiceActing: "Дубляж (Red Head Sound)",
                        quality: "720p",
                        videoURL: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
                    ),
                    VideoSource(
                        voiceActing: "HDRezka Studio",
                        quality: "1080p",
                        videoURL: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
                    ),
                    VideoSource(
                        voiceActing: "HDRezka Studio",
                        quality: "720p",
                        videoURL: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
                    )
                ]
            ),
            // 2. Аркейн (Сериал, 2 сезон, 2024)
            Movie(
                id: "arcane_s2_2024",
                title: "Аркейн (2 сезон)",
                originalTitle: "Arcane: League of Legends",
                description: "Второй и финальный сезон анимационного шедевра. Напряжение между утопическим Пилтовером и угнетенным подземным Зауном достигает предела после теракта Джинкс. Сестры Вай и Джинкс оказываются по разные стороны баррикад в назревающей разрушительной войне, которая навсегда изменит мир Рунтерры.",
                ratingKp: 9.0,
                ratingImdb: 9.1,
                year: 2024,
                duration: "9 серий",
                genres: ["Мультфильм", "Фантастика", "Боевик", "Драма", "Фэнтези"],
                countries: ["США", "Франция"],
                director: "Паскаль Шаррю",
                actors: ["Хейли Стайнфилд", "Элла Пернелл", "Кевин Алехандро"],
                posterURL: "https://images.unsplash.com/photo-1618336753974-aae8e04506aa?auto=format&fit=crop&q=80&w=600",
                bannerURL: "https://images.unsplash.com/photo-1614850523459-c2f4c699c52e?auto=format&fit=crop&q=80&w=1200",
                isSeries: true,
                isFeatured: false,
                videoSources: [
                    VideoSource(
                        voiceActing: "Дубляж (Netflix)",
                        quality: "1080p",
                        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                    ),
                    VideoSource(
                        voiceActing: "LostFilm",
                        quality: "1080p",
                        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
                    ),
                    VideoSource(
                        voiceActing: "HDRezka Studio",
                        quality: "1080p",
                        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
                    )
                ]
            ),
            // 3. Дюна: Часть вторая (Фильм, 2024)
            Movie(
                id: "dune_part2_2024",
                title: "Дюна: Часть вторая",
                originalTitle: "Dune: Part Two",
                description: "Пол Атрейдес объединяется с Чани и фременами, чтобы отомстить заговорщикам, уничтожившим его семью. Между любовью всей своей жизни и судьбой известной вселенной он пытается предотвратить ужасное будущее, которое может предвидеть только он.",
                ratingKp: 8.5,
                ratingImdb: 8.6,
                year: 2024,
                duration: "166 мин.",
                genres: ["Фантастика", "Боевик", "Приключения", "Драма"],
                countries: ["США", "Канада"],
                director: "Дени Вильнёв",
                actors: ["Тимоти Шаламе", "Зендея", "Ребекка Фергюсон", "Остин Батлер", "Флоренс Пью"],
                posterURL: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&q=80&w=600",
                bannerURL: "https://images.unsplash.com/photo-1547234935-80c7145ec969?auto=format&fit=crop&q=80&w=1200",
                isSeries: false,
                isFeatured: false,
                videoSources: [
                    VideoSource(
                        voiceActing: "Дубляж",
                        quality: "1080p",
                        videoURL: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
                    ),
                    VideoSource(
                        voiceActing: "Дубляж",
                        quality: "720p",
                        videoURL: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
                    )
                ]
            ),
            // 4. Джентльмены (Сериал, 2024)
            Movie(
                id: "gentlemen_s1_2024",
                title: "Джентльмены",
                originalTitle: "The Gentlemen",
                description: "Эдди Хорниман неожиданно наследует огромное загородное поместье своего отца-герцога и обнаруживает, что оно является частью подпольной империи марихуаны. Более того, ряд несимпатичных персонажей из преступного мира Великобритании хотят прибрать этот бизнес к своим рукам.",
                ratingKp: 7.8,
                ratingImdb: 8.1,
                year: 2024,
                duration: "8 серий",
                genres: ["Боевик", "Комедия", "Криминал"],
                countries: ["Великобритания", "США"],
                director: "Гай Ричи",
                actors: ["Тео Джеймс", "Кая Скоделарио", "Дэниэл Ингс", "Винни Джонс"],
                posterURL: "https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&q=80&w=600",
                bannerURL: "https://images.unsplash.com/photo-1513151233558-d860c5398176?auto=format&fit=crop&q=80&w=1200",
                isSeries: true,
                isFeatured: false,
                videoSources: [
                    VideoSource(
                        voiceActing: "HDRezka Studio",
                        quality: "1080p",
                        videoURL: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
                    ),
                    VideoSource(
                        voiceActing: "LostFilm",
                        quality: "1080p",
                        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                    ),
                    VideoSource(
                        voiceActing: "Кубик в Кубе",
                        quality: "1080p",
                        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
                    )
                ]
            ),
            // 5. Дэдпул и Росомаха (Фильм, 2024)
            Movie(
                id: "deadpool_wolverine_2024",
                title: "Дэдпул и Росомаха",
                originalTitle: "Deadpool & Wolverine",
                description: "Уэйд Уилсон сталкивается с бюрократической организацией «Управление временными изменениями», которая угрожает его домашней вселенной. Чтобы спасти свой мир от уничтожения, Уэйд вытаскивает сломленную версию Росомахи из другой вселенной, чтобы объединить силы.",
                ratingKp: 7.6,
                ratingImdb: 7.8,
                year: 2024,
                duration: "128 мин.",
                genres: ["Фантастика", "Боевик", "Комедия"],
                countries: ["США"],
                director: "Шон Леви",
                actors: ["Райан Рейнольдс", "Хью Джекман", "Эмма Коррин", "Мэттью Макфэдьен"],
                posterURL: "https://images.unsplash.com/photo-1635805737707-575885ab0820?auto=format&fit=crop&q=80&w=600",
                bannerURL: "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&q=80&w=1200",
                isSeries: false,
                isFeatured: false,
                videoSources: [
                    VideoSource(
                        voiceActing: "Дубляж (Red Head Sound)",
                        quality: "1080p",
                        videoURL: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
                    ),
                    VideoSource(
                        voiceActing: "HDRezka Studio",
                        quality: "1080p",
                        videoURL: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
                    )
                ]
            ),
            // 6. Игра престолов (Сериал, 2011-2019)
            Movie(
                id: "got_2011",
                title: "Игра престолов",
                originalTitle: "Game of Thrones",
                description: "Эпическое фэнтези о борьбе за Железный трон Семи Королевств. Пока благородные дома плетут интриги, предают друг друга и сражаются за власть, на севере за Ледяной Стеной пробуждается древнее зло, угрожающее стереть человечество с лица земли.",
                ratingKp: 9.0,
                ratingImdb: 9.2,
                year: 2019,
                duration: "73 серии",
                genres: ["Фэнтези", "Драма", "Боевик", "Мелодрама"],
                countries: ["США", "Великобритания"],
                director: "Дэвид Наттер",
                actors: ["Эмилия Кларк", "Кит Харингтон", "Питер Динклэйдж", "Лина Хиди"],
                posterURL: "https://images.unsplash.com/photo-1560169897-fc0cdbdfa4d5?auto=format&fit=crop&q=80&w=600",
                bannerURL: "https://images.unsplash.com/photo-1519074069444-1ba4e6663104?auto=format&fit=crop&q=80&w=1200",
                isSeries: true,
                isFeatured: false,
                videoSources: [
                    VideoSource(
                        voiceActing: "Дубляж (Amedia)",
                        quality: "1080p",
                        videoURL: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
                    ),
                    VideoSource(
                        voiceActing: "LostFilm",
                        quality: "1080p",
                        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                    ),
                    VideoSource(
                        voiceActing: "Fox",
                        quality: "720p",
                        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
                    )
                ]
            )
        ]
    }
    
    // Асинхронное обновление каталога
    public func fetchCatalog() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Имитация сетевой задержки для реалистичного UI перехода
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 секунд
            loadLocalDatabase()
        } catch {
            errorMessage = "Не удалось обновить каталог с сайта Киного"
        }
        
        isLoading = false
    }
    
    // Поиск фильма по названию или оригинальному названию
    public func searchMovies(query: String) -> [Movie] {
        guard !query.isEmpty else { return movies }
        return movies.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.originalTitle.localizedCaseInsensitiveContains(query)
        }
    }
    
    // Поиск фильмов по сложным фильтрам
    public func filterMovies(
        genre: String?,
        year: Int?,
        isSeries: Bool?,
        sortByRating: Bool = false
    ) -> [Movie] {
        var filtered = movies
        
        if let genre = genre, genre != "Все" {
            filtered = filtered.filter { $0.genres.contains(genre) }
        }
        
        if let year = year {
            filtered = filtered.filter { $0.year == year }
        }
        
        if let isSeries = isSeries {
            filtered = filtered.filter { $0.isSeries == isSeries }
        }
        
        if sortByRating {
            filtered = filtered.sorted(by: { $0.ratingKp > $1.ratingKp })
        } else {
            // По умолчанию сортируем по новизне (по году выпуска)
            filtered = filtered.sorted(by: { $0.year > $1.year })
        }
        
        return filtered
    }
}
