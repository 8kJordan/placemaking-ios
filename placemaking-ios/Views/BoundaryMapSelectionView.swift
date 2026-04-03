//
//  BoundaryMapSelectionView.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct BoundaryMapSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let startingPoint: ProjectLocationChoice
    let existingBoundary: ProjectBoundary?
    let onSelect: (MapSelectionResult) -> Void

    @StateObject private var locationManager = LocationAuthorizationManager()
    @State private var draftBoundary: ProjectBoundary
    @State private var requestedCenter: GeoCoordinate?

    private let fallbackCenter = GeoCoordinate(latitude: 37.3349, longitude: -122.0090)

    init(
        startingPoint: ProjectLocationChoice,
        existingBoundary: ProjectBoundary?,
        onSelect: @escaping (MapSelectionResult) -> Void
    ) {
        self.startingPoint = startingPoint
        self.existingBoundary = existingBoundary
        self.onSelect = onSelect
        _draftBoundary = State(initialValue: existingBoundary ?? ProjectBoundary(
            center: GeoCoordinate(latitude: 37.3349, longitude: -122.0090),
            widthMeters: 18,
            heightMeters: 18
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let statusMessage = locationManager.statusMessage, startingPoint == .currentLocation {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                }

                BoundarySelectingMapRepresentable(
                    boundary: $draftBoundary,
                    requestedCenter: requestedCenter ?? existingBoundary?.center ?? fallbackCenter,
                    showsUserLocation: startingPoint == .currentLocation
                )
                .ignoresSafeArea(edges: .bottom)

                HStack(spacing: 12) {
                    MeasurementStat(title: "Width", value: draftBoundary.widthMeters.lengthText)
                    MeasurementStat(title: "Height", value: draftBoundary.heightMeters.lengthText)
                    MeasurementStat(title: "Area", value: draftBoundary.areaSquareMeters.areaText)
                }
                .padding(16)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Select Boundary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Use Boundary") {
                        onSelect(MapSelectionResult(boundary: draftBoundary))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("confirmBoundaryButton")
                }
            }
        }
        .onAppear {
            if startingPoint == .currentLocation {
                locationManager.requestCurrentLocation()
            }
        }
        .onReceive(locationManager.$currentCoordinate) { coordinate in
            guard startingPoint == .currentLocation, let coordinate else { return }
            requestedCenter = coordinate
        }
    }
}

private struct BoundarySelectingMapRepresentable: UIViewRepresentable {
    @Binding var boundary: ProjectBoundary

    let requestedCenter: GeoCoordinate
    let showsUserLocation: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(boundary: $boundary)
    }

    func makeUIView(context: Context) -> BoundarySelectingMapContainerView {
        let view = BoundarySelectingMapContainerView()
        view.onBoundaryChange = { newBoundary in
            context.coordinator.boundary.wrappedValue = newBoundary
        }
        view.configure(center: requestedCenter, showsUserLocation: showsUserLocation)
        return view
    }

    func updateUIView(_ uiView: BoundarySelectingMapContainerView, context: Context) {
        uiView.configure(center: requestedCenter, showsUserLocation: showsUserLocation)
    }

    final class Coordinator {
        var boundary: Binding<ProjectBoundary>

        init(boundary: Binding<ProjectBoundary>) {
            self.boundary = boundary
        }
    }
}

private final class BoundarySelectingMapContainerView: UIView, MKMapViewDelegate {
    private let mapView = MKMapView(frame: .zero)
    private let overlayView = RectangleSelectionOverlayView(frame: .zero)

    private var hasConfiguredInitialRect = false
    private var lastCenteredCoordinate: GeoCoordinate?

    var onBoundaryChange: ((ProjectBoundary) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !hasConfiguredInitialRect, bounds.width > 0, bounds.height > 0 {
            overlayView.selectionRect = bounds.insetBy(dx: 32, dy: 160)
            hasConfiguredInitialRect = true
            refreshBoundary()
        }
    }

    func configure(center: GeoCoordinate, showsUserLocation: Bool) {
        if lastCenteredCoordinate != center {
            lastCenteredCoordinate = center
            let region = MKCoordinateRegion(
                center: center.clCoordinate,
                latitudinalMeters: 120,
                longitudinalMeters: 120
            )
            mapView.setRegion(region, animated: true)
        }

        mapView.showsUserLocation = showsUserLocation
    }

    private func setup() {
        backgroundColor = .systemBackground

        mapView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        mapView.delegate = self
        mapView.mapType = .hybrid
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .excludingAll
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false

        addSubview(mapView)
        addSubview(overlayView)

        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        overlayView.onSelectionChanged = { [weak self] _ in
            self?.refreshBoundary()
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        refreshBoundary()
    }

    private func refreshBoundary() {
        guard hasConfiguredInitialRect else { return }

        let rect = overlayView.selectionRect
        let topLeft = mapView.convert(CGPoint(x: rect.minX, y: rect.minY), toCoordinateFrom: overlayView)
        let topRight = mapView.convert(CGPoint(x: rect.maxX, y: rect.minY), toCoordinateFrom: overlayView)
        let bottomLeft = mapView.convert(CGPoint(x: rect.minX, y: rect.maxY), toCoordinateFrom: overlayView)
        let centerCoordinate = mapView.convert(CGPoint(x: rect.midX, y: rect.midY), toCoordinateFrom: overlayView)

        let boundary = ProjectBoundary(
            center: GeoCoordinate(centerCoordinate),
            widthMeters: BoundaryGeometry.distanceMeters(from: GeoCoordinate(topLeft), to: GeoCoordinate(topRight)),
            heightMeters: BoundaryGeometry.distanceMeters(from: GeoCoordinate(topLeft), to: GeoCoordinate(bottomLeft))
        )

        onBoundaryChange?(boundary)
    }
}

private final class RectangleSelectionOverlayView: UIView {
    enum DragMode {
        case move
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    var selectionRect: CGRect = .zero {
        didSet {
            setNeedsDisplay()
        }
    }

    var onSelectionChanged: ((CGRect) -> Void)?

    private let minimumSize: CGFloat = 96
    private let handleRadius: CGFloat = 14

    private var dragMode: DragMode?
    private var startingRect: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard selectionRect != .zero else { return false }

        if selectionRect.insetBy(dx: -24, dy: -24).contains(point) {
            return true
        }

        return handleCenters.contains { center in
            center.distance(to: point) <= handleRadius + 14
        }
    }

    override func draw(_ rect: CGRect) {
        guard selectionRect != .zero else { return }

        let selectionPath = UIBezierPath(roundedRect: selectionRect, cornerRadius: 22)
        UIColor.systemBlue.withAlphaComponent(0.08).setFill()
        selectionPath.fill()

        UIColor.white.withAlphaComponent(0.85).setStroke()
        selectionPath.lineWidth = 3
        selectionPath.stroke()

        drawCenterGuides()
        drawHandles()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let translation = gesture.translation(in: self)

        switch gesture.state {
        case .began:
            dragMode = dragMode(for: location)
            startingRect = selectionRect
        case .changed:
            guard let dragMode else { return }

            selectionRect = adjustedRect(for: dragMode, translation: translation)
            onSelectionChanged?(selectionRect)
        case .ended, .cancelled, .failed:
            dragMode = nil
        default:
            break
        }
    }

    private func drawCenterGuides() {
        let verticalGuide = UIBezierPath()
        verticalGuide.move(to: CGPoint(x: selectionRect.midX, y: selectionRect.minY + 12))
        verticalGuide.addLine(to: CGPoint(x: selectionRect.midX, y: selectionRect.maxY - 12))
        verticalGuide.lineWidth = 1
        UIColor.white.withAlphaComponent(0.34).setStroke()
        verticalGuide.stroke()

        let horizontalGuide = UIBezierPath()
        horizontalGuide.move(to: CGPoint(x: selectionRect.minX + 12, y: selectionRect.midY))
        horizontalGuide.addLine(to: CGPoint(x: selectionRect.maxX - 12, y: selectionRect.midY))
        horizontalGuide.lineWidth = 1
        UIColor.white.withAlphaComponent(0.34).setStroke()
        horizontalGuide.stroke()
    }

    private func drawHandles() {
        for center in handleCenters {
            let handleRect = CGRect(
                x: center.x - handleRadius,
                y: center.y - handleRadius,
                width: handleRadius * 2,
                height: handleRadius * 2
            )
            let path = UIBezierPath(ovalIn: handleRect)
            UIColor.white.setFill()
            path.fill()

            UIColor.systemBlue.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }

    private func dragMode(for point: CGPoint) -> DragMode? {
        let handleZones = zip(handleCenters, [DragMode.topLeft, .topRight, .bottomLeft, .bottomRight])

        for (center, mode) in handleZones where center.distance(to: point) <= handleRadius + 14 {
            return mode
        }

        return selectionRect.contains(point) ? .move : nil
    }

    private func adjustedRect(for dragMode: DragMode, translation: CGPoint) -> CGRect {
        var updatedRect = startingRect

        switch dragMode {
        case .move:
            updatedRect.origin.x += translation.x
            updatedRect.origin.y += translation.y
        case .topLeft:
            updatedRect.origin.x += translation.x
            updatedRect.origin.y += translation.y
            updatedRect.size.width -= translation.x
            updatedRect.size.height -= translation.y
        case .topRight:
            updatedRect.origin.y += translation.y
            updatedRect.size.width += translation.x
            updatedRect.size.height -= translation.y
        case .bottomLeft:
            updatedRect.origin.x += translation.x
            updatedRect.size.width -= translation.x
            updatedRect.size.height += translation.y
        case .bottomRight:
            updatedRect.size.width += translation.x
            updatedRect.size.height += translation.y
        }

        if updatedRect.width < minimumSize {
            switch dragMode {
            case .topLeft, .bottomLeft:
                updatedRect.origin.x -= minimumSize - updatedRect.width
            default:
                break
            }
            updatedRect.size.width = minimumSize
        }

        if updatedRect.height < minimumSize {
            switch dragMode {
            case .topLeft, .topRight:
                updatedRect.origin.y -= minimumSize - updatedRect.height
            default:
                break
            }
            updatedRect.size.height = minimumSize
        }

        if updatedRect.minX < 16 {
            if dragMode == .move {
                updatedRect.origin.x = 16
            } else {
                let delta = 16 - updatedRect.minX
                updatedRect.origin.x += delta
                updatedRect.size.width -= delta
            }
        }

        if updatedRect.minY < 80 {
            if dragMode == .move {
                updatedRect.origin.y = 80
            } else {
                let delta = 80 - updatedRect.minY
                updatedRect.origin.y += delta
                updatedRect.size.height -= delta
            }
        }

        if updatedRect.maxX > bounds.width - 16 {
            let overflow = updatedRect.maxX - (bounds.width - 16)
            if dragMode == .move {
                updatedRect.origin.x -= overflow
            } else {
                updatedRect.size.width -= overflow
            }
        }

        if updatedRect.maxY > bounds.height - 16 {
            let overflow = updatedRect.maxY - (bounds.height - 16)
            if dragMode == .move {
                updatedRect.origin.y -= overflow
            } else {
                updatedRect.size.height -= overflow
            }
        }

        return updatedRect.standardized
    }

    private var handleCenters: [CGPoint] {
        [
            CGPoint(x: selectionRect.minX, y: selectionRect.minY),
            CGPoint(x: selectionRect.maxX, y: selectionRect.minY),
            CGPoint(x: selectionRect.minX, y: selectionRect.maxY),
            CGPoint(x: selectionRect.maxX, y: selectionRect.maxY),
        ]
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

extension Double {
    var lengthText: String {
        String(format: "%.1f m", self)
    }

    var areaText: String {
        String(format: "%.1f m²", self)
    }
}
