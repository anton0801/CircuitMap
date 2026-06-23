//
//  SplashView.swift
//  CircuitMap
//
//  Thematic launch animation: circuit traces light up and travel, then
//  converge into a lightning-bolt logo. Single coordinator timer, 3+
//  simultaneous animated layers, full loop teardown on disappear.
//

import SwiftUI
import Combine
import Network

/// A lightning-bolt logo path drawn in a unit-ish coordinate box.
struct LightningBolt: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.56, y: h * 0.04))
        p.addLine(to: CGPoint(x: w * 0.20, y: h * 0.56))
        p.addLine(to: CGPoint(x: w * 0.46, y: h * 0.56))
        p.addLine(to: CGPoint(x: w * 0.40, y: h * 0.96))
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.40))
        p.addLine(to: CGPoint(x: w * 0.54, y: h * 0.40))
        p.closeSubpath()
        return p
    }
}

/// Horizontal circuit traces with right-angle steps used in the splash.
struct SplashTraces: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let ys: [CGFloat] = [0.18, 0.34, 0.5, 0.66, 0.82]
        for (i, yf) in ys.enumerated() {
            let y = rect.height * yf
            p.move(to: CGPoint(x: 0, y: y))
            let mid = rect.width * (i % 2 == 0 ? 0.4 : 0.6)
            p.addLine(to: CGPoint(x: mid, y: y))
            let stepY = y + (i % 2 == 0 ? 28 : -28)
            p.addLine(to: CGPoint(x: mid, y: stepY))
            p.addLine(to: CGPoint(x: rect.width, y: stepY))
        }
        return p
    }
}

struct SplashView: View {

    // staged reveal flags
    @State private var showGrid = false
    @State private var drawTraces: CGFloat = 0
    @State private var showLogo = false
    @State private var drawBolt: CGFloat = 0
    @State private var showTitle = false
    @State private var exiting = false

    // looping flags
    @State private var networkMonitor = NWPathMonitor()
    @State private var sparkTravel = false
    @State private var nodePulse = false
    @State private var glowPulse = false

    // coordinator
    @State private var isVisible = true
    
    @StateObject private var readout = Readout()
    @State private var startTime: Date?
    @State private var timer: Timer?
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ZStack {
                    // ---- Layer 1: background gradient + grid ----
                    // Theme.background.ignoresSafeArea()
                    Color.black.ignoresSafeArea()
                    
                    Image("citcuit_main_loading")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .opacity(0.45)

                    GeometryReader { geo in
                        CircuitTrace(spacing: 44)
                            .stroke(Theme.primary.opacity(showGrid ? 0.06 : 0), lineWidth: 0.8)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .ignoresSafeArea()
                    
                    NavigationLink(
                        destination: ScreenView().navigationBarHidden(true),
                        isActive: $readout.navigateToWeb
                    ) { EmptyView() }

                    // ---- Layer 2: lighting-up circuit traces + travelling spark ----
                    ZStack {
                        SplashTraces()
                            .trim(from: 0, to: drawTraces)
                            .stroke(Theme.circuit.opacity(0.5),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .shadow(color: Theme.circuitGlow, radius: 6)

                        // travelling spark glow along the traces
                        SplashTraces()
                            .trim(from: sparkTravel ? 0.85 : 0.0, to: sparkTravel ? 1.0 : 0.15)
                            .stroke(Theme.primaryHi,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .shadow(color: Theme.sparkGlow, radius: 10)
                            .opacity(drawTraces >= 1 ? 1 : 0)
                    }
                    .frame(width: 300, height: 240)
                    .scaleEffect(exiting ? 1.5 : 1)
                    .opacity(exiting ? 0 : 1)
                    
                    NavigationLink(
                        destination: RootView().navigationBarBackButtonHidden(true),
                        isActive: $readout.navigateToMain
                    ) { EmptyView() }

                    // ---- Layer 3: bolt logo + title ----
                    VStack(spacing: 20) {
//                        ZStack {
//                            // pulsing node halo
//                            Circle()
//                                .fill(Theme.primary.opacity(0.12))
//                                .frame(width: 132, height: 132)
//                                .scaleEffect(nodePulse ? 1.12 : 0.9)
//                                .opacity(showLogo ? 1 : 0)
//
//                            Circle()
//                                .stroke(Theme.primary.opacity(0.6), lineWidth: 2)
//                                .frame(width: 108, height: 108)
//                                .opacity(showLogo ? 1 : 0)
//
//                            LightningBolt()
//                                .trim(from: 0, to: drawBolt)
//                                .stroke(Theme.primaryGradient,
//                                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
//                                .frame(width: 70, height: 86)
//                                .shadow(color: Theme.sparkGlow, radius: glowPulse ? 16 : 8)
//
//                            LightningBolt()
//                                .fill(Theme.primary.opacity(drawBolt >= 1 ? 0.9 : 0))
//                                .frame(width: 70, height: 86)
//                                .shadow(color: Theme.sparkGlow, radius: glowPulse ? 14 : 6)
//                        }
//                        .scaleEffect(showLogo ? (exiting ? 1.6 : 1) : 0.4)
//                        .opacity(showLogo ? (exiting ? 0 : 1) : 0)

                        VStack(spacing: 6) {
                            Text("CIRCUIT MAP")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .tracking(3)
                                .foregroundColor(.white)
                        }
                        .opacity(showTitle ? (exiting ? 0 : 1) : 0)
                        .offset(y: showTitle ? 0 : 12)
                    }
                }
                .fullScreenCover(isPresented: $readout.showPermissionPrompt) {
                    ConsentPanel(readout: readout)
                }
                .fullScreenCover(isPresented: $readout.showOfflineView) {
                    OfflinePanel()
                }
                .onAppear { start() }
                .onDisappear { teardown() }
            }
            .ignoresSafeArea()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func wireNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                readout.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    
    private func start() {
        wireStreams()
        wireNetworkMonitoring()
        readout.ignite()
        isVisible = true
        // looping layers
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: false)) {
            sparkTravel = true
        }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            nodePulse = true
        }
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowPulse = true
        }

        startTime = Date()
        let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard isVisible, let start = startTime else { return }
        // Wall-clock elapsed so timer starvation can't stretch the sequence.
        let elapsed = Date().timeIntervalSince(start)
        if elapsed >= 0.1 && !showGrid {
            withAnimation(.easeOut(duration: 0.6)) { showGrid = true }
        }
        if elapsed >= 0.55 && drawTraces == 0 {
            withAnimation(.easeInOut(duration: 0.9)) { drawTraces = 1 }
        }
        if elapsed >= 1.4 && !showLogo {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { showLogo = true }
            withAnimation(.easeInOut(duration: 0.7)) { drawBolt = 1 }
        }
        if elapsed >= 1.9 && !showTitle {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { showTitle = true }
        }
    }

    private func teardown() {
        isVisible = false
        startTime = nil
        timer?.invalidate(); timer = nil
        sparkTravel = false
        nodePulse = false
        glowPulse = false
        showGrid = false
        drawTraces = 0
        showLogo = false
        drawBolt = 0
        showTitle = false
    }
    
    private func wireStreams() {
        NotificationCenter.default.publisher(for: .signalArrived)
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                readout.ingestSignal(data)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .jumpersArrived)
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                readout.ingestJumpers(data)
            }
            .store(in: &cancellables)
    }
    
}

struct ConsentPanel: View {
    let readout: Readout

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                Image("circuit_main")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)

                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    landscapeView
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var landscapeView: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                titleText
                subtitleText
            }
            Spacer()
            VStack {
                Spacer()
                actionButtons
            }
            Spacer()
        }
        .padding(.bottom, 24)
    }

    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 23, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }

    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                readout.acceptConsent()
            } label: {
                Image("citcuit_main_b")
                    .resizable()
                    .frame(width: 300, height: 55)
            }

            Button {
                readout.skipConsent()
            } label: {
                Image("citcuit_main_sec")
                    .resizable()
                    .frame(width: 270, height: 36)
            }
        }
        .padding(.horizontal, 12)
    }
}

struct OfflinePanel: View {
    
    private var errorView: some View {
        Image("citcuit_error")
            .resizable()
            .frame(width: 230, height: 270)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("citcuit_error_image")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)
                    .blur(radius: 3)
                
                errorView
            }
        }
        .ignoresSafeArea()
    }
    
}
