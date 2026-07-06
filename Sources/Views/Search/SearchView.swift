import SwiftUI

/// Экран поиска фильмов и сериалов Киного с детальной фильтрацией
@MainActor
public struct SearchView: View {
    @StateObject private var service = MovieService()
    @State private var searchText: String = ""
    
    // Фильтры
    @State private var selectedGenre: String = "Все"
    @State private var selectedYear: Int? = nil
    @State private var selectedType: String = "Все" // Все, Фильмы, Сериалы
    @State private var sortByRating: Bool = false
    @State private var showFilterSheet: Bool = false
    
    private let types = ["Все", "Фильмы", "Сериалы"]
    
    // Жанры для фильтрации
    private var genresList: [String] {
        var genres = ["Все"]
        let allGenres = service.movies.flatMap { $0.genres }
        genres.append(contentsOf: allGenres.unique())
        return genres
    }
    
    // Года для фильтрации
    private var yearsList: [Int] {
        let years = service.movies.map { $0.year }
        return Array(Set(years)).sorted(by: >)
    }
    
    // Список лет с опцией "Любой" для разгрузки компилятора
    private var filterYearsList: [String] {
        ["Любой"] + yearsList.map { String($0) }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 1. Поисковая строка и Кнопка Фильтров
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            TextField("Поиск фильмов, сериалов...", text: $searchText)
                                .foregroundColor(Theme.Colors.textPrimary)
                                .tint(Theme.Colors.accent)
                                .font(.system(size: 15, weight: .medium))
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.surface)
                        .cornerRadius(Theme.Radius.card)
                        .neonGlowBorder(radius: Theme.Radius.card, isGlowing: !searchText.isEmpty)
                        
                        // Кнопка открытия панели фильтров
                        Button(action: { showFilterSheet = true }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(hasActiveFilters ? Theme.Colors.accent : .white)
                                .padding(12)
                                .background(Theme.Colors.surface)
                                .cornerRadius(Theme.Radius.card)
                                .neonGlowBorder(radius: Theme.Radius.card, isGlowing: hasActiveFilters)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Активные теги фильтров под поиском
                    if hasActiveFilters {
                        activeFilterBadgesView()
                    }
                    
                    // 2. Список результатов
                    let results = getFilteredResults()
                    
                    if results.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles.tv")
                                .font(.system(size: 54))
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text(searchText.isEmpty && !hasActiveFilters ? "Попробуйте найти что-то новое" : "По вашему запросу ничего не найдено")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(results) { movie in
                                    NavigationLink(value: movie) {
                                        SearchRowView(movie: movie)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Поиск Киного")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            // Лист Фильтров
            .sheet(isPresented: $showFilterSheet) {
                filterSheetView()
            }
        }
    }
    
    // MARK: - Filter Logic & Subviews
    
    private var hasActiveFilters: Bool {
        selectedGenre != "Все" || selectedYear != nil || selectedType != "Все" || sortByRating
    }
    
    private func getFilteredResults() -> [Movie] {
        var baseList = service.movies
        
        // Поиск по слову
        if !searchText.isEmpty {
            baseList = service.searchMovies(query: searchText)
        }
        
        // Фильтр по жанру
        if selectedGenre != "Все" {
            baseList = baseList.filter { $0.genres.contains(selectedGenre) }
        }
        
        // Фильтр по году
        if let year = selectedYear {
            baseList = baseList.filter { $0.year == year }
        }
        
        // Фильтр по типу (фильм/сериал)
        if selectedType == "Фильмы" {
            baseList = baseList.filter { !$0.isSeries }
        } else if selectedType == "Сериалы" {
            baseList = baseList.filter { $0.isSeries }
        }
        
        // Сортировка
        if sortByRating {
            baseList = baseList.sorted(by: { $0.ratingKp > $1.ratingKp })
        } else {
            baseList = baseList.sorted(by: { $0.year > $1.year })
        }
        
        return baseList
    }
    
    private func clearFilters() {
        selectedGenre = "Все"
        selectedYear = nil
        selectedType = "Все"
        sortByRating = false
    }
    
    @ViewBuilder
    private func activeFilterBadgesView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if selectedGenre != "Все" {
                    filterBadge(text: selectedGenre) { selectedGenre = "Все" }
                }
                if let year = selectedYear {
                    filterBadge(text: String(year)) { selectedYear = nil }
                }
                if selectedType != "Все" {
                    filterBadge(text: selectedType) { selectedType = "Все" }
                }
                if sortByRating {
                    filterBadge(text: "Сначала высокий рейтинг") { sortByRating = false }
                }
                
                Button(action: clearFilters) {
                    Text("Сбросить все")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.Colors.accent)
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func filterBadge(text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.Colors.accent)
        .cornerRadius(6)
    }
    
    // MARK: - Filter Sheet View & Subcomponents
    
    @ViewBuilder
    private func typeFilterSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Категория")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 10) {
                ForEach(types, id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        Text(type)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedType == type ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedType == type ? Theme.Colors.accent : Theme.Colors.surface)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func genreFilterSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Жанр")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            FlowLayout(items: genresList) { genre in
                Button(action: { selectedGenre = genre }) {
                    Text(genre)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedGenre == genre ? .black : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedGenre == genre ? Theme.Colors.accent : Theme.Colors.surface)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    @ViewBuilder
    private func yearFilterSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Год выпуска")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            FlowLayout(items: filterYearsList) { yearStr in
                let isSelected = (yearStr == "Любой" && selectedYear == nil) || (selectedYear == Int(yearStr))
                Button(action: {
                    if yearStr == "Любой" {
                        selectedYear = nil
                    } else {
                        selectedYear = Int(yearStr)
                    }
                }) {
                    Text(yearStr)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .black : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? Theme.Colors.accent : Theme.Colors.surface)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sortFilterSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Сортировка")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Toggle(isOn: $sortByRating) {
                Text("По рейтингу Кинопоиска")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .tint(Theme.Colors.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.surface)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func filterSheetView() -> some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        typeFilterSection()
                        genreFilterSection()
                        yearFilterSection()
                        sortFilterSection()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Сбросить") {
                        clearFilters()
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Применить") {
                        showFilterSheet = false
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Row View для результатов поиска

struct SearchRowView: View {
    let movie: Movie
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: movie.posterURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 100)
                        .cornerRadius(Theme.Radius.card)
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(Theme.Colors.surfaceSecondary)
                        .frame(width: 70, height: 100)
                }
            }
            .neonGlowBorder(radius: Theme.Radius.card)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(movie.originalTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
                
                Text("\(movie.genres.prefix(2).joined(separator: ", ")) • \(movie.year)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                HStack(spacing: 8) {
                    // Рейтинг КП
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Theme.Colors.accent)
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", movie.ratingKp))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.surfaceSecondary)
                    .cornerRadius(4)
                    
                    if movie.isSeries {
                        Text("Сериал")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.Colors.accent)
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(10)
        .background(Theme.Colors.surface)
        .cornerRadius(Theme.Radius.card)
        .neonGlowBorder(radius: Theme.Radius.card)
    }
}

// MARK: - FlowLayout Helper для списков тегов

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                self.content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == self.items.last {
                            width = 0 // последний элемент
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if item == self.items.last {
                            height = 0 // последний
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}
