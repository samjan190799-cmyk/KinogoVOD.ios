import SwiftUI
import AVKit

/// Кастомный видеоплеер с поддержкой жестов (яркость, громкость, перемотка) и переключением потоков озвучки/качества
public struct AdvancedVideoPlayer: View {
    let movie: Movie
    @Binding var selectedSource: VideoSource
    let onDismiss: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isDraggingSlider = false
    @State private var isLocked = false // Блокировка управления
    
    // Переменные для жестов
    @State private var brightnessVal: Double = UIScreen.main.brightness
    @State private var volumeVal: Float = 0.5 // Внутренняя громкость плеера
    @State private var gestureIndicatorType: GestureIndicatorType? = nil
    @State private var gestureIndicatorValue: Double = 0.0
    @State private var seekGestureOffset: Double = 0.0
    @State private var initialSeekTime: Double = 0.0
    
    // Таймер скрытия контролов
    @State private var controlsTimer: Task<Void, Never>? = nil
    
    enum GestureIndicatorType {
        case brightness
        case volume
        case seek
    }
    
    public init(movie: Movie, selectedSource: Binding<VideoSource>, onDismiss: @escaping () -> Void) {
        self.movie = movie
        self._selectedSource = selectedSource
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                // Видеопроигрыватель
                if let player = player {
                    VideoPlayerRepresentable(player: player)
                        .ignoresSafeArea()
                        .onTapGesture {
                            if !isLocked {
                                toggleControls()
                            } else {
                                // Если заблокировано, показываем только кнопку разблокировки на короткое время
                                withAnimation(Theme.Animations.interactiveSpring) {
                                    showControls = true
                                }
                                resetControlsTimer()
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    if isLocked { return }
                                    handleDragGesture(value, in: geometry.size)
                                }
                                .onEnded { value in
                                    if isLocked { return }
                                    handleDragEnded(value)
                                }
                        )
                } else {
                    ProgressView("Загрузка видеопотока...")
                        .tint(Theme.Colors.accent)
                        .foregroundColor(.white)
                }
                
                // Эффект темного оверлея при отображении органов управления
                if showControls && !isLocked {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                
                // UI управления плеером
                if showControls {
                    controlsOverlay(size: geometry.size)
                }
                
                // Индикаторы жестов (яркость, громкость, перемотка) по центру экрана
                gestureIndicatorOverlay()
            }
            .statusBarHidden(!showControls)
            .onAppear {
                setupPlayer(with: selectedSource.videoURL)
            }
            .onDisappear {
                saveCurrentProgress()
                player?.pause()
                controlsTimer?.cancel()
            }
            .onChange(of: selectedSource) { newSource in
                saveCurrentProgress() // Сохраняем прогресс старого потока
                setupPlayer(with: newSource.videoURL) // Загружаем новый поток
            }
        }
    }
    
    // MARK: - UI Controls Overlay
    
    @ViewBuilder
    private func controlsOverlay(size: CGSize) -> some View {
        VStack {
            // 1. Верхняя панель управления
            if !isLocked {
                HStack {
                    Button(action: {
                        saveCurrentProgress()
                        player?.pause()
                        onDismiss()
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movie.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(movie.isSeries ? "Сериал" : "Фильм")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Меню выбора качества и озвучки
                    Menu {
                        Section("Озвучка") {
                            ForEach(movie.videoSources.map({ $0.voiceActing }).unique(), id: \.self) { voice in
                                Button(action: { selectVoice(voice) }) {
                                    HStack {
                                        Text(voice)
                                        if selectedSource.voiceActing == voice {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section("Качество") {
                            ForEach(movie.videoSources.filter({ $0.voiceActing == selectedSource.voiceActing }), id: \.id) { src in
                                Button(action: { selectedSource = src }) {
                                    HStack {
                                        Text(src.quality)
                                        if selectedSource.quality == src.quality {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                            Text("\(selectedSource.quality) • \(selectedSource.voiceActing)")
                                .lineLimit(1)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(Theme.Radius.button)
                        .neonGlowBorder(radius: Theme.Radius.button, isGlowing: false)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                .transition(.move(edge: .top))
            } else {
                Spacer().frame(height: 50)
            }
            
            Spacer()
            
            // 2. Центральная кнопка воспроизведения и кнопка блокировки
            HStack(spacing: 80) {
                if !isLocked {
                    Button(action: { skip(-15) }) {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.white)
                    }
                }
                
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(Theme.Colors.accent)
                }
                
                if !isLocked {
                    Button(action: { skip(15) }) {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.white)
                    }
                }
            }
            .transition(.scale)
            
            Spacer()
            
            // 3. Нижняя панель управления и кнопка лока экрана
            HStack(alignment: .bottom) {
                // Кнопка блокировки экрана
                Button(action: {
                    withAnimation(Theme.Animations.interactiveSpring) {
                        isLocked.toggle()
                        showControls = true
                        resetControlsTimer()
                    }
                }) {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .neonGlowBorder(radius: 24, isGlowing: isLocked)
                }
                .padding(.bottom, 4)
                
                if !isLocked {
                    // Слайдер времени и прогресс
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Text(formatTime(currentTime))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                            
                            // Кастомный слайдер
                            Slider(value: $currentTime, in: 0...max(1, duration), onEditingChanged: { editing in
                                isDraggingSlider = editing
                                if !editing {
                                    seekToTime(currentTime)
                                }
                            })
                            .tint(Theme.Colors.accent)
                            
                            Text(formatTime(duration))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        
                        // Дополнительная информация о буферизации/видеопотоке
                        Text("Киного стриминг • \(selectedSource.voiceActing) [\(selectedSource.quality)]")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(Theme.Radius.card)
                    .neonGlowBorder(radius: Theme.Radius.card)
                    .padding(.leading, 8)
                }
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 20)
            .transition(.move(edge: .bottom))
        }
    }
    
    // MARK: - Gesture Indicator Overlay
    
    @ViewBuilder
    private func gestureIndicatorOverlay() -> some View {
        if let type = gestureIndicatorType {
            VStack(spacing: 12) {
                Image(systemName: indicatorIconName(type))
                    .font(.system(size: 40))
                    .foregroundColor(Theme.Colors.accent)
                
                if type == .seek {
                    Text(formatTime(gestureIndicatorValue))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    ProgressView(value: gestureIndicatorValue, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: Theme.Colors.accent))
                        .frame(width: 120)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .neonGlowBorder(radius: 18, isGlowing: true)
            .transition(.opacity)
        }
    }
    
    private func indicatorIconName(_ type: GestureIndicatorType) -> String {
        switch type {
        case .brightness:
            return gestureIndicatorValue > 0.5 ? "sun.max.fill" : "sun.min.fill"
        case .volume:
            return gestureIndicatorValue == 0 ? "speaker.slash.fill" : (gestureIndicatorValue > 0.5 ? "speaker.wave.3.fill" : "speaker.wave.1.fill")
        case .seek:
            return seekGestureOffset > 0 ? "goforward" : "gobackward"
        }
    }
    
    // MARK: - Logic & Actions
    
    private func setupPlayer(with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // Паузим старый плеер
        player?.pause()
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.volume = volumeVal // Устанавливаем громкость
        self.player = newPlayer
        
        // Слушаем изменения времени воспроизведения
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if !isDraggingSlider {
                self.currentTime = time.seconds
            }
            if let durationTime = newPlayer.currentItem?.duration.seconds, !durationTime.isNaN {
                self.duration = durationTime
            }
        }
        
        // Восстановление сохраненного прогресса
        let progress = StorageService.shared.getProgress(movieId: movie.id)
        if let savedPos = progress?.position, savedPos < (duration - 15) {
            let cmTime = CMTime(seconds: savedPos, preferredTimescale: 1000)
            newPlayer.seek(to: cmTime)
            self.currentTime = savedPos
        }
        
        newPlayer.play()
        isPlaying = true
        resetControlsTimer()
    }
    
    private func togglePlayPause() {
        resetControlsTimer()
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    private func toggleControls() {
        withAnimation(Theme.Animations.interactiveSpring) {
            showControls.toggle()
        }
        if showControls {
            resetControlsTimer()
        } else {
            controlsTimer?.cancel()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.cancel()
        controlsTimer = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 секунды
            if !Task.isCancelled && isPlaying && !isDraggingSlider {
                withAnimation(Theme.Animations.smoothFade) {
                    showControls = false
                }
            }
        }
    }
    
    private func seekToTime(_ time: Double) {
        resetControlsTimer()
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime)
    }
    
    private func skip(_ seconds: Double) {
        resetControlsTimer()
        let targetTime = currentTime + seconds
        let clampedTime = max(0, min(duration, targetTime))
        seekToTime(clampedTime)
    }
    
    private func selectVoice(_ voice: String) {
        // Находим первый доступный источник с этой озвучкой
        if let newSource = movie.videoSources.first(where: { $0.voiceActing == voice }) {
            self.selectedSource = newSource
        }
    }
    
    private func saveCurrentProgress() {
        guard duration > 0 else { return }
        StorageService.shared.saveProgress(
            movieId: movie.id,
            movieTitle: movie.title,
            posterURL: movie.posterURL,
            source: selectedSource,
            position: currentTime,
            duration: duration
        )
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN else { return "00:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
    
    // MARK: - Drag Gestures (Brightness, Volume, Seek)
    
    private func handleDragGesture(_ value: DragGesture.Value, in size: CGSize) {
        // Определяем тип жеста при начале движения
        if gestureIndicatorType == nil {
            let startLoc = value.startLocation
            // Если движение горизонтальное
            if abs(value.translation.width) > abs(value.translation.height) {
                gestureIndicatorType = .seek
                initialSeekTime = currentTime
            } else {
                // Вертикальное движение: левая половина экрана - яркость, правая - громкость
                if startLoc.x < size.width / 2 {
                    gestureIndicatorType = .brightness
                    brightnessVal = Double(UIScreen.main.brightness)
                } else {
                    gestureIndicatorType = .volume
                    volumeVal = player?.volume ?? 0.5
                }
            }
        }
        
        guard let type = gestureIndicatorType else { return }
        
        // Вычисляем изменения
        switch type {
        case .brightness:
            let delta = Double(-value.translation.height / size.height) // инвертируем, свайп вверх - ярче
            let newVal = max(0.0, min(1.0, brightnessVal + delta))
            UIScreen.main.brightness = CGFloat(newVal)
            gestureIndicatorValue = newVal
            
        case .volume:
            let delta = Float(-value.translation.height / size.height) // свайп вверх - громче
            let newVal = max(0.0, min(1.0, volumeVal + delta))
            player?.volume = newVal
            gestureIndicatorValue = Double(newVal)
            
        case .seek:
            let ratio = Double(value.translation.width / size.width)
            let timeDelta = ratio * 120.0 // максимальный жест = 2 минуты перемотки
            seekGestureOffset = timeDelta
            let targetTime = max(0.0, min(duration, initialSeekTime + timeDelta))
            gestureIndicatorValue = targetTime
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        if gestureIndicatorType == .seek {
            let targetTime = gestureIndicatorValue
            seekToTime(targetTime)
            self.currentTime = targetTime
        }
        
        // Запоминаем текущую громкость в переменную
        if gestureIndicatorType == .volume {
            volumeVal = player?.volume ?? 0.5
        }
        
        // Скрываем индикатор с анимацией
        withAnimation(Theme.Animations.smoothFade) {
            gestureIndicatorType = nil
        }
        
        resetControlsTimer()
    }
}

// MARK: - Unique Array Helper

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - UIViewControllerRepresentable для AVPlayer

struct VideoPlayerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false // Скрываем стандартный UI
        controller.videoGravity = .resizeAspect
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
