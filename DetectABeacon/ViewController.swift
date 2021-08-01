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
	@IBOutlet var deviceName: UILabel!
	@IBOutlet var detectionCircle: UIView!

	// MARK: - Properties
	private enum Device: String, CaseIterable {
		case iPad = "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5"
		case airPods = "5A4BCFCE-174E-4BAC-A814-092E77F6B7E6"
		case iPhone = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
		case unknown = "🤷🏻‍♂️"

		var name: String {
			switch self {
			case .iPad: return "iPad"
			case .airPods: return "Air Pods"
			case .iPhone: return "iPhone Настя"
			case .unknown: return "No devices"
			}
		}
	}
	private var locationManager: CLLocationManager?
	private var didShowFindBeaconAlert: Bool = false

	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		configureDetectionCircle()

		locationManager = CLLocationManager()
		locationManager?.delegate = self
		locationManager?.requestAlwaysAuthorization()
	}

	// MARK: - Subviews
	private func configureDetectionCircle() {
		detectionCircle.layer.masksToBounds = true
		detectionCircle.layer.cornerRadius = 128
		detectionCircle.backgroundColor = UIColor.init(white: 1, alpha: 0)
	}

	// MARK: - Beacons
	typealias Beacon = (identity: CLBeaconIdentityConstraint, region: CLBeaconRegion)

	private func iPadBeacon() -> Beacon {
		let uuid = UUID(uuidString: Device.iPad.rawValue)!
		let identity = CLBeaconIdentityConstraint(uuid: uuid, major: 123, minor: 456)
		let region = CLBeaconRegion(beaconIdentityConstraint: identity, identifier: "iPad")
		return (identity, region)
	}

	private func airPodsBeacon() -> Beacon {
		let uuid = UUID(uuidString: Device.airPods.rawValue)!
		let identity = CLBeaconIdentityConstraint(uuid: uuid, major: 123, minor: 456)
		let region = CLBeaconRegion(beaconIdentityConstraint: identity, identifier: "AirPods")
		return (identity, region)
	}

	private func iPhoneNastya() -> Beacon {
		let uuid = UUID(uuidString: Device.iPhone.rawValue)!
		let identity = CLBeaconIdentityConstraint(uuid: uuid, major: 14, minor: 88)
		let region = CLBeaconRegion(beaconIdentityConstraint: identity, identifier: "iPhone")
		return (identity, region)
	}

	// MARK: - Beacons Detection
	private func startScanning(beacon: Beacon) {
		locationManager?.startRangingBeacons(satisfying: beacon.identity)
		locationManager?.startMonitoring(for: beacon.region)
	}

	private func update(distance: CLProximity, to device: Device) {
		UIView.animate(withDuration: 1) {
			switch distance {
			case .far:
				self.detectionCircle.backgroundColor = .blue
				self.detectionCircle.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
				self.distanceReading.text = "FAR"
			case .near:
				self.detectionCircle.backgroundColor = .orange
				self.detectionCircle.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
				self.distanceReading.text = "NEAR"
			case .immediate:
				self.detectionCircle.backgroundColor = .red
				self.detectionCircle.transform = CGAffineTransform(scaleX: 1, y: 1)
				self.distanceReading.text = "RIGHT HERE"
			default:
				self.detectionCircle.backgroundColor = .gray
				self.detectionCircle.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
				self.distanceReading.text = "Unknown"
			}
			self.deviceName.text = device.name
		}
	}

	// MARK: - Alerts
	private func showBeaconDetectedAlert() {
		let alertController = UIAlertController(title: "Beacon detected", message: "We have detected your beacon", preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Cool", style: .default))
		present(alertController, animated: UIView.areAnimationsEnabled)
		didShowFindBeaconAlert = true
	}
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		guard status == .authorizedAlways,
			  CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self),
			  CLLocationManager.isRangingAvailable() else { return }
		startScanning(beacon: iPadBeacon())
		startScanning(beacon: airPodsBeacon())
		startScanning(beacon: iPhoneNastya())
	}

	func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
		guard !beacons.isEmpty else { return }

		let knownBeaconsUUIDs = Device.allCases.map { $0.rawValue }
		guard let beacon = beacons.first(where: { knownBeaconsUUIDs.contains($0.uuid.uuidString) }),
			  let device = Device(rawValue: beacon.uuid.uuidString) else {
			return update(distance: .unknown, to: .unknown)
		}

		update(distance: beacon.proximity, to: device)
		if !didShowFindBeaconAlert {
			showBeaconDetectedAlert()
		}
	}
}
