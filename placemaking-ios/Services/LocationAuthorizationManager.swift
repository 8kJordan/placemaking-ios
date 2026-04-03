//
//  LocationAuthorizationManager.swift
//  placemaking-ios
//
//  Created by Codex on 4/1/26.
//

import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationAuthorizationManager: NSObject, ObservableObject {
    @Published private(set) var currentCoordinate: GeoCoordinate?
    @Published private(set) var statusMessage: String?

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestCurrentLocation() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            statusMessage = nil
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            statusMessage = "Location access is unavailable, so the map is using a default starting area."
        @unknown default:
            statusMessage = "Current location is unavailable right now. You can still place the boundary manually."
        }
    }
}

extension LocationAuthorizationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            statusMessage = nil
            manager.requestLocation()
        case .restricted, .denied:
            statusMessage = "Location access is unavailable, so the map is using a default starting area."
        case .notDetermined:
            break
        @unknown default:
            statusMessage = "Current location is unavailable right now. You can still place the boundary manually."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentCoordinate = GeoCoordinate(location.coordinate)
        statusMessage = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        statusMessage = "Could not resolve your location. You can continue by positioning the map yourself."
    }
}
