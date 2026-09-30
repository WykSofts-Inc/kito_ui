## 0.1.0

- First release: `KitoScannerView` on mobile_scanner (scan window matched to the
  viewfinder, de-duplicated detections, lock-on feedback, torch and camera switching, a
  friendly camera-permission screen), `KitoScanOverlay` (corners, laser, frame and minimal
  styles; works over any child; Reduce Motion aware) with the pure `KitoScanWindow` geometry,
  `KitoScannerControlBar`, `KitoScanResultCard` and `KitoScanResultSheet` with actions per
  payload, and the pure `KitoScanParser` (links, Wi-Fi, MECARD and vCard contacts, phone,
  email, SMS, geo, M-Pesa till / paybill / phone payment codes, EAN/UPC products with GS1
  origin) plus `KitoScanCheckDigits` (GS1, UPC-E, Luhn).
