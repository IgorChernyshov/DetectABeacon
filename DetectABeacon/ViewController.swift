//
//  ViewController.swift
//  DetectABeacon
//
//  Created by Igor Chernyshov on 01.08.2021.
//

import UIKit
import CoreLocation

final class ViewController: UIViewController {

	// MARK: - Outlets
	@IBOutlet var distanceReading: UILabel!

	// MARK: - Properties
	private var locationManager: CLLocationManager?

	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		locationManager = CLLocationManager()
		locationManager?.delegate = self
		locationManager?.requestAlwaysAuthorization()

		view.backgroundColor = .gray
	}

	// MARK: - Beacon Detection
	private func startScanning() {
		let uuid = UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!
		let beaconIdentityConstraint = CLBeaconIdentityConstraint(uuid: uuid, major: 123, minor: 456)
		locationManager?.startRangingBeacons(satisfying: beaconIdentityConstraint)

		let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: beaconIdentityConstraint, identifier: "MyBeacon")
		locationManager?.startMonitoring(for: beaconRegion)
	}

	private func update(distance: CLProximity) {
		UIView.animate(withDuration: 1) {
			switch distance {
			case .far:
				self.view.backgroundColor = UIColor.blue
				self.distanceReading.text = "FAR"
			case .near:
				self.view.backgroundColor = UIColor.orange
				self.distanceReading.text = "NEAR"
			case .immediate:
				self.view.backgroundColor = UIColor.red
				self.distanceReading.text = "RIGHT HERE"
			default:
				self.view.backgroundColor = UIColor.gray
				self.distanceReading.text = "UNKNOWN"
			}
		}
	}
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		guard status == .authorizedAlways,
			  CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self),
			  CLLocationManager.isRangingAvailable() else { return }
		startScanning()
	}

	func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
		if let beacon = beacons.first {
			update(distance: beacon.proximity)
		} else {
			update(distance: .unknown)
		}
	}
}
