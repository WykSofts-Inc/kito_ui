// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_scanner/kito_ui_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('parser', () {
    test('links', () {
      final p = KitoScanParser.parse('https://kito.ke/menu?t=4') as KitoScanUrl;
      expect(p.summary, 'kito.ke');
      expect(KitoScanParser.parse('www.safaricom.co.ke'), isA<KitoScanUrl>());
      expect(KitoScanParser.parse('hello world'), isA<KitoScanText>());
    });

    test('wi-fi', () {
      final w =
          KitoScanParser.parse(
                r'WIFI:T:WPA;S:Java House\;Guest;P:karibu2026;H:true;;',
              )
              as KitoScanWifi;
      expect(w.ssid, 'Java House;Guest');
      expect(w.password, 'karibu2026');
      expect(w.security, KitoScanWifiSecurity.wpa);
      expect(w.hidden, isTrue);
      final open =
          KitoScanParser.parse('WIFI:S:Free;T:nopass;;') as KitoScanWifi;
      expect(open.security, KitoScanWifiSecurity.open);
      expect(open.password, isNull);
    });

    test('contacts', () {
      final m =
          KitoScanParser.parse(
                'MECARD:N:Wanjiru,Amina;TEL:0712345678;TEL:0722000000;EMAIL:amina@kito.ke;ORG:Kito;;',
              )
              as KitoScanContact;
      expect(m.name, 'Amina Wanjiru');
      expect(m.phones, ['0712345678', '0722000000']);
      expect(m.emails, ['amina@kito.ke']);
      expect(m.organization, 'Kito');

      final v =
          KitoScanParser.parse(
                'BEGIN:VCARD\nVERSION:3.0\nN:Otieno;Brian;;;\n'
                'FN:Brian Otieno\nTEL;TYPE=CELL:+254 733 111 222\nTITLE:Rider\n'
                'ADR:;;Moi Avenue;Nairobi;;00100;Kenya\nEND:VCARD',
              )
              as KitoScanContact;
      expect(v.name, 'Brian Otieno');
      expect(v.phones, ['+254 733 111 222']);
      expect(v.jobTitle, 'Rider');
      expect(v.address, 'Moi Avenue, Nairobi, 00100, Kenya');
    });

    test('phone, email, sms and geo', () {
      expect(
        (KitoScanParser.parse('tel:+254712345678') as KitoScanPhone).number,
        '+254712345678',
      );
      final e =
          KitoScanParser.parse('mailto:hello@kito.ke?subject=Order')
              as KitoScanEmail;
      expect(e.address, 'hello@kito.ke');
      expect(e.subject, 'Order');
      expect(KitoScanParser.parse('jambo@kito.ke'), isA<KitoScanEmail>());
      final s =
          KitoScanParser.parse('SMSTO:0712345678:Niko njiani') as KitoScanSms;
      expect(s.number, '0712345678');
      expect(s.body, 'Niko njiani');
      final g =
          KitoScanParser.parse('geo:-1.2864,36.8172?q=KICC') as KitoScanGeo;
      expect(g.latitude, -1.2864);
      expect(g.summary, 'KICC');
      expect(KitoScanParser.parse('geo:200,1'), isA<KitoScanText>());
    });

    test('M-Pesa payments', () {
      final p =
          KitoScanParser.parse(
                'kitopay://till?number=123456&amount=1500&name=Mama%20Mboga',
              )
              as KitoScanPayment;
      expect(p.kind, KitoScanPaymentKind.till);
      expect(p.number, '123456');
      expect(p.amount, 150000);
      expect(p.formattedAmount, 'KES 1,500');
      expect(p.merchant, 'Mama Mboga');
      final b =
          KitoScanParser.parse('kitopay://paybill/247247?account=ACC-9')
              as KitoScanPayment;
      expect(b.kind, KitoScanPaymentKind.paybill);
      expect(b.number, '247247');
      expect(b.account, 'ACC-9');
      expect(
        KitoScanParser.parse('kitopay://nope?number=1'),
        isA<KitoScanText>(),
      );
    });

    test('products and check digits', () {
      final p = KitoScanParser.parse('6161001234567') as KitoScanProduct;
      expect(p.format, KitoScanFormat.ean13);
      expect(p.isValid, isTrue);
      expect(p.origin, 'Kenya');
      expect(
        (KitoScanParser.parse('6161001234560') as KitoScanProduct).isValid,
        isFalse,
      );
      expect(
        KitoScanParser.parse('12345', format: KitoScanFormat.qr),
        isA<KitoScanText>(),
      );
      expect(
        KitoScanParser.parse('6161001234567', format: KitoScanFormat.qr),
        isA<KitoScanText>(),
      );
      expect(KitoScanCheckDigits.gtinCheckDigit('616100123456'), 7);
      expect(KitoScanCheckDigits.expandUpcE('04252614'), '042100005264');
      expect(KitoScanCheckDigits.isValidUpcE('04252614'), isTrue);
      expect(KitoScanCheckDigits.isValidLuhn('4242 4242 4242 4242'), isTrue);
      expect(KitoScanCheckDigits.isValidLuhn('4242 4242 4242 4241'), isFalse);
    });

    test('scanned code parses its payload', () {
      final c = KitoScannedCode('https://kito.ke');
      expect(c.payload, isA<KitoScanUrl>());
      expect(c, KitoScannedCode('https://kito.ke'));
    });
  });

  test('actions per payload', () {
    List<KitoScanActionKind> kinds(String raw) =>
        KitoScanAction.forCode(
          KitoScannedCode(raw),
        ).map((a) => a.kind).toList();
    expect(kinds('https://kito.ke'), [
      KitoScanActionKind.open,
      KitoScanActionKind.copy,
    ]);
    expect(kinds('tel:0712345678'), [
      KitoScanActionKind.call,
      KitoScanActionKind.message,
      KitoScanActionKind.copy,
    ]);
    final wifi = KitoScanAction.forCode(
      KitoScannedCode('WIFI:S:Home;T:WPA;P:secret;;'),
    );
    expect(wifi.last.value, 'secret');
    final pay = KitoScanAction.forCode(
      KitoScannedCode('kitopay://till?number=5&amount=200'),
    );
    expect(pay.first.label, 'Pay KES 200');
  });

  test('scan window and laser', () {
    final r = KitoScanWindow.rect(const Size(400, 800));
    expect(r.width, 288);
    expect(r.height, 288);
    expect(r.center.dx, 200);
    expect(r.center.dy, lessThan(400));
    final wide = KitoScanWindow.rect(const Size(400, 800), aspectRatio: 2);
    expect(wide.height, 144);
    expect(KitoScanWindow.laserOffset(0, 100), 14);
    expect(KitoScanWindow.laserOffset(1, 100), closeTo(86, 1e-9));
    expect(KitoScanWindow.laserOffset(2, 100), closeTo(14, 1e-9));
    expect(KitoScanWindow.bracketLength(r), 44);
    expect(KitoScanWindow.rect(Size.zero), Rect.zero);
  });

  test('mobile_scanner formats map to Kito formats', () {
    expect(kitoScanFormatOf(BarcodeFormat.qrCode), KitoScanFormat.qr);
    expect(kitoScanFormatOf(BarcodeFormat.ean13), KitoScanFormat.ean13);
    expect(kitoScanFormatOf(BarcodeFormat.itf14), KitoScanFormat.itf);
    expect(kitoScanFormatOf(BarcodeFormat.maxiCode), KitoScanFormat.unknown);
  });
}
