// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/material.dart';

/// Barcode formats the scanner reports, independent of the camera plugin.
enum KitoScanFormat {
  /// QR code.
  qr('QR', true),

  /// Aztec.
  aztec('Aztec', true),

  /// PDF417 (boarding passes, IDs).
  pdf417('PDF417', true),

  /// Data Matrix.
  dataMatrix('Data Matrix', true),

  /// EAN-13.
  ean13('EAN-13', false),

  /// EAN-8.
  ean8('EAN-8', false),

  /// UPC-A.
  upcA('UPC-A', false),

  /// UPC-E.
  upcE('UPC-E', false),

  /// Code 128.
  code128('Code 128', false),

  /// Code 39.
  code39('Code 39', false),

  /// Code 93.
  code93('Code 93', false),

  /// ITF / ITF-14.
  itf('ITF', false),

  /// Codabar.
  codabar('Codabar', false),

  /// Anything else.
  unknown('Code', false);

  const KitoScanFormat(this.title, this.isTwoDimensional);

  /// "EAN-13".
  final String title;

  /// QR, Aztec, PDF417 and Data Matrix.
  final bool isTwoDimensional;

  /// Product barcodes: EAN, UPC and ITF.
  bool get isRetail =>
      this == ean13 ||
      this == ean8 ||
      this == upcA ||
      this == upcE ||
      this == itf;
}

/// What a code means, parsed from its text.
sealed class KitoScanPayload {
  const KitoScanPayload();

  /// "Link", "Wi-Fi network".
  String get kindTitle;

  /// A matching icon.
  IconData get icon;

  /// One line for a list: the host, the network name, the contact's name.
  String get summary;
}

/// A web link.
class KitoScanUrl extends KitoScanPayload {
  /// Creates a link.
  const KitoScanUrl(this.uri);

  /// The link.
  final Uri uri;

  @override
  String get kindTitle => 'Link';
  @override
  IconData get icon => Icons.link_rounded;
  @override
  String get summary => uri.host.isEmpty ? uri.toString() : uri.host;
}

/// Wi-Fi security.
enum KitoScanWifiSecurity {
  /// No password.
  open('Open'),

  /// WPA / WPA2 / WPA3.
  wpa('WPA'),

  /// WEP.
  wep('WEP');

  const KitoScanWifiSecurity(this.title);

  /// "WPA".
  final String title;
}

/// A Wi-Fi network (`WIFI:S:…;T:WPA;P:…;;`).
class KitoScanWifi extends KitoScanPayload {
  /// Creates a network.
  const KitoScanWifi({
    required this.ssid,
    this.password,
    this.security = KitoScanWifiSecurity.wpa,
    this.hidden = false,
  });

  /// The network name.
  final String ssid;

  /// The password, or null for open networks.
  final String? password;

  /// The security.
  final KitoScanWifiSecurity security;

  /// Whether the network hides its name.
  final bool hidden;

  @override
  String get kindTitle => 'Wi-Fi network';
  @override
  IconData get icon => Icons.wifi_rounded;
  @override
  String get summary => ssid;
}

/// A contact card (MECARD or vCard).
class KitoScanContact extends KitoScanPayload {
  /// Creates a contact.
  const KitoScanContact({
    required this.name,
    this.phones = const [],
    this.emails = const [],
    this.organization,
    this.jobTitle,
    this.address,
    this.website,
    this.note,
  });

  /// "Amina Wanjiru".
  final String name;

  /// Phone numbers.
  final List<String> phones;

  /// Email addresses.
  final List<String> emails;

  /// The company.
  final String? organization;

  /// The role.
  final String? jobTitle;

  /// A postal address.
  final String? address;

  /// A website.
  final String? website;

  /// A note.
  final String? note;

  @override
  String get kindTitle => 'Contact';
  @override
  IconData get icon => Icons.contact_page_rounded;
  @override
  String get summary => name.isEmpty ? (phones.firstOrNull ?? 'Contact') : name;
}

/// A phone number (`tel:`).
class KitoScanPhone extends KitoScanPayload {
  /// Creates a phone number.
  const KitoScanPhone(this.number);

  /// The number as written.
  final String number;

  @override
  String get kindTitle => 'Phone number';
  @override
  IconData get icon => Icons.call_rounded;
  @override
  String get summary => number;
}

/// An email (`mailto:` or `MATMSG:`).
class KitoScanEmail extends KitoScanPayload {
  /// Creates an email.
  const KitoScanEmail(this.address, {this.subject, this.body});

  /// The recipient.
  final String address;

  /// The subject.
  final String? subject;

  /// The body.
  final String? body;

  @override
  String get kindTitle => 'Email';
  @override
  IconData get icon => Icons.email_rounded;
  @override
  String get summary => address;
}

/// A text message (`SMSTO:number:body`).
class KitoScanSms extends KitoScanPayload {
  /// Creates a message.
  const KitoScanSms(this.number, {this.body});

  /// The recipient.
  final String number;

  /// The prefilled text.
  final String? body;

  @override
  String get kindTitle => 'Text message';
  @override
  IconData get icon => Icons.sms_rounded;
  @override
  String get summary => number;
}

/// A place (`geo:lat,lng?q=…`).
class KitoScanGeo extends KitoScanPayload {
  /// Creates a place.
  const KitoScanGeo(this.latitude, this.longitude, {this.query});

  /// Latitude.
  final double latitude;

  /// Longitude.
  final double longitude;

  /// A label or search.
  final String? query;

  /// "-1.28640, 36.81720".
  String get coordinateText =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  @override
  String get kindTitle => 'Location';
  @override
  IconData get icon => Icons.place_rounded;
  @override
  String get summary => query ?? coordinateText;
}

/// How an M-Pesa style payment is addressed.
enum KitoScanPaymentKind {
  /// A Buy Goods till number.
  till('Till number'),

  /// A Paybill business number with an account.
  paybill('Paybill'),

  /// Send money to a phone.
  phone('Phone');

  const KitoScanPaymentKind(this.title);

  /// "Till number".
  final String title;
}

/// A payment request: `kitopay://till?number=123456&amount=1500&name=Mama%20Mboga`.
class KitoScanPayment extends KitoScanPayload {
  /// Creates a request. [amount] is in minor units (cents).
  const KitoScanPayment({
    required this.kind,
    required this.number,
    this.account,
    this.amount,
    this.currency = 'KES',
    this.merchant,
    this.note,
  });

  /// Till, paybill or phone.
  final KitoScanPaymentKind kind;

  /// The till, business or phone number.
  final String number;

  /// The paybill account.
  final String? account;

  /// Cents, or null to let the customer type it.
  final int? amount;

  /// The ISO 4217 code.
  final String currency;

  /// Who's being paid.
  final String? merchant;

  /// A reference.
  final String? note;

  /// "KES 1,500", or null.
  String? get formattedAmount {
    if (amount == null) return null;
    final major = amount! ~/ 100, minor = amount! % 100;
    final s = major.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '$currency $b${minor == 0 ? '' : '.${minor.toString().padLeft(2, '0')}'}';
  }

  @override
  String get kindTitle => 'Payment';
  @override
  IconData get icon => Icons.payments_rounded;
  @override
  String get summary => merchant ?? number;
}

/// A product barcode.
class KitoScanProduct extends KitoScanPayload {
  /// Creates a product code.
  const KitoScanProduct(this.digits, {required this.format});

  /// The digits.
  final String digits;

  /// EAN-13, EAN-8, UPC-A, UPC-E or ITF.
  final KitoScanFormat format;

  /// Whether the check digit is right.
  bool get isValid =>
      format == KitoScanFormat.upcE
          ? KitoScanCheckDigits.isValidUpcE(digits)
          : KitoScanCheckDigits.isValidGtin(digits);

  /// The GS1 prefix country for EAN-13 codes, when it's one we know: 616 is Kenya.
  String? get origin {
    if (digits.length != 13) return null;
    final p = int.tryParse(digits.substring(0, 3)) ?? -1;
    return switch (p) {
      616 => 'Kenya',
      620 => 'Tanzania',
      615 => 'Nigeria',
      629 => 'United Arab Emirates',
      890 => 'India',
      >= 600 && <= 601 => 'South Africa',
      >= 690 && <= 699 => 'China',
      >= 400 && <= 440 => 'Germany',
      >= 500 && <= 509 => 'United Kingdom',
      >= 0 && <= 139 => 'United States or Canada',
      _ => null,
    };
  }

  @override
  String get kindTitle => 'Product';
  @override
  IconData get icon => Icons.qr_code_2_rounded;
  @override
  String get summary => digits;
}

/// Plain text.
class KitoScanText extends KitoScanPayload {
  /// Creates text.
  const KitoScanText(this.text);

  /// The text.
  final String text;

  @override
  String get kindTitle => 'Text';
  @override
  IconData get icon => Icons.notes_rounded;
  @override
  String get summary => text;
}

/// One scan: the raw text, its format, when it was seen and what it means.
@immutable
class KitoScannedCode {
  /// Creates a scan; [payload] is parsed from [raw] when left out.
  KitoScannedCode(
    this.raw, {
    this.format = KitoScanFormat.qr,
    DateTime? scannedAt,
    KitoScanPayload? payload,
  }) : scannedAt = scannedAt ?? DateTime.now(),
       payload = payload ?? KitoScanParser.parse(raw, format: format);

  /// Exactly what the code holds.
  final String raw;

  /// Its format.
  final KitoScanFormat format;

  /// When it was scanned.
  final DateTime scannedAt;

  /// What it means.
  final KitoScanPayload payload;

  @override
  bool operator ==(Object other) =>
      other is KitoScannedCode && other.raw == raw && other.format == format;

  @override
  int get hashCode => Object.hash(raw, format);
}

/// Turns a code's text into a [KitoScanPayload]. Pure and unit tested.
abstract final class KitoScanParser {
  /// The scheme of [KitoScanPayment] codes.
  static const String paymentScheme = 'kitopay';

  /// Parses [raw]; [format] helps tell product codes from numbers.
  static KitoScanPayload parse(String raw, {KitoScanFormat? format}) {
    final text = raw.trim();
    final upper = text.toUpperCase();
    final product = _product(text, format);
    if (product != null) return product;
    if (upper.startsWith('WIFI:')) {
      final w = _wifi(text);
      if (w != null) return w;
    }
    if (upper.startsWith('MECARD:')) {
      final c = _mecard(text);
      if (c != null) return c;
    }
    if (upper.startsWith('BEGIN:VCARD')) {
      final c = _vcard(text);
      if (c != null) return c;
    }
    if (upper.startsWith('${paymentScheme.toUpperCase()}:')) {
      final p = _payment(text);
      if (p != null) return p;
    }
    if (upper.startsWith('TEL:')) {
      final n = _phone(text.substring(4));
      if (n != null) return KitoScanPhone(n);
    }
    if (upper.startsWith('MAILTO:')) {
      final uri = Uri.tryParse(text);
      if (uri != null && uri.path.contains('@')) {
        return KitoScanEmail(
          Uri.decodeComponent(uri.path),
          subject: uri.queryParameters['subject'],
          body: uri.queryParameters['body'],
        );
      }
    }
    if (upper.startsWith('MATMSG:')) {
      final f = _fields(text.substring(7));
      final to = f['TO'];
      if (to != null && to.isNotEmpty) {
        return KitoScanEmail(to, subject: f['SUB'], body: f['BODY']);
      }
    }
    if (upper.startsWith('SMSTO:') || upper.startsWith('SMS:')) {
      final rest = text.substring(text.indexOf(':') + 1);
      final i = rest.indexOf(':');
      final number = (i < 0 ? rest : rest.substring(0, i)).split('?').first;
      final body =
          i < 0
              ? Uri.tryParse(text)?.queryParameters['body']
              : rest.substring(i + 1);
      if (_phone(number) != null) {
        return KitoScanSms(
          number,
          body: body == null || body.isEmpty ? null : body,
        );
      }
    }
    if (upper.startsWith('GEO:')) {
      final g = _geo(text);
      if (g != null) return g;
    }
    final url = _url(text);
    if (url != null) return KitoScanUrl(url);
    if (RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(text)) {
      return KitoScanEmail(text);
    }
    if (text.startsWith('+') && _phone(text) != null) {
      return KitoScanPhone(text);
    }
    return KitoScanText(text);
  }

  static KitoScanProduct? _product(String text, KitoScanFormat? format) {
    if (!RegExp(r'^\d+$').hasMatch(text)) return null;
    if (format != null &&
        !format.isRetail &&
        format != KitoScanFormat.unknown) {
      return null;
    }
    return switch (text.length) {
      8 => KitoScanProduct(
        text,
        format:
            format == KitoScanFormat.upcE
                ? KitoScanFormat.upcE
                : KitoScanFormat.ean8,
      ),
      12 => KitoScanProduct(text, format: KitoScanFormat.upcA),
      13 => KitoScanProduct(text, format: KitoScanFormat.ean13),
      14 => KitoScanProduct(text, format: KitoScanFormat.itf),
      _ => null,
    };
  }

  /// Splits `K:value;K2:value;` with `\;` `\:` `\\` escapes.
  static Map<String, String> _fields(String body) {
    final out = <String, String>{};
    final buf = StringBuffer();
    String? key;
    for (var i = 0; i < body.length; i++) {
      final ch = body[i];
      if (ch == r'\' && i + 1 < body.length) {
        buf.write(body[++i]);
      } else if (ch == ':' && key == null) {
        key = buf.toString().trim().toUpperCase();
        buf.clear();
      } else if (ch == ';') {
        if (key != null) {
          out.putIfAbsent(key, () => buf.toString());
          if (key == 'TEL' || key == 'EMAIL') {
            out['$key#${out.length}'] = buf.toString();
          }
        }
        key = null;
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    if (key != null && buf.isNotEmpty) {
      out.putIfAbsent(key, () => buf.toString());
    }
    return out;
  }

  static KitoScanWifi? _wifi(String text) {
    final f = _fields(text.substring(5));
    final ssid = f['S'];
    if (ssid == null || ssid.isEmpty) return null;
    final type = (f['T'] ?? '').toUpperCase();
    final password = (f['P'] ?? '').isEmpty ? null : f['P'];
    final security = switch (type) {
      'WEP' => KitoScanWifiSecurity.wep,
      '' || 'NOPASS' || 'NONE' =>
        password == null ? KitoScanWifiSecurity.open : KitoScanWifiSecurity.wpa,
      _ => KitoScanWifiSecurity.wpa,
    };
    return KitoScanWifi(
      ssid: ssid,
      password: security == KitoScanWifiSecurity.open ? null : password,
      security: security,
      hidden: (f['H'] ?? '').toLowerCase() == 'true',
    );
  }

  static KitoScanContact? _mecard(String text) {
    final f = _fields(text.substring(7));
    var name = f['N'] ?? '';
    if (name.contains(',')) {
      final parts = name.split(',').map((p) => p.trim()).toList();
      name = '${parts.length > 1 ? parts[1] : ''} ${parts[0]}'.trim();
    }
    List<String> all(String key) =>
        {
          for (final e in f.entries)
            if (e.key == key || e.key.startsWith('$key#')) e.value,
        }.toList();
    final phones = all('TEL'), emails = all('EMAIL');
    if (name.isEmpty && phones.isEmpty && emails.isEmpty) return null;
    return KitoScanContact(
      name: name,
      phones: phones,
      emails: emails,
      organization: f['ORG'],
      address: f['ADR'],
      website: f['URL'],
      note: f['NOTE'],
    );
  }

  static KitoScanContact? _vcard(String text) {
    final lines = <String>[];
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      if ((raw.startsWith(' ') || raw.startsWith('\t')) && lines.isNotEmpty) {
        lines[lines.length - 1] += raw.substring(1);
      } else {
        lines.add(raw);
      }
    }
    String? fn, n, org, title, adr, url, note;
    final phones = <String>[], emails = <String>[];
    for (final line in lines) {
      final i = line.indexOf(':');
      if (i < 0) continue;
      final key = line.substring(0, i).split(';').first.toUpperCase();
      final value =
          line
              .substring(i + 1)
              .replaceAll(r'\n', '\n')
              .replaceAll(r'\,', ',')
              .replaceAll(r'\;', ';')
              .trim();
      switch (key) {
        case 'FN':
          fn = value;
        case 'N':
          final p = value.split(';');
          n = '${p.length > 1 ? p[1] : ''} ${p[0]}'.trim();
        case 'TEL':
          phones.add(value);
        case 'EMAIL':
          emails.add(value);
        case 'ORG':
          org = value.split(';').first;
        case 'TITLE':
          title = value;
        case 'ADR':
          adr = value
              .split(';')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .join(', ');
        case 'URL':
          url = value;
        case 'NOTE':
          note = value;
      }
    }
    final name = fn ?? n ?? '';
    if (name.isEmpty && phones.isEmpty && emails.isEmpty) return null;
    return KitoScanContact(
      name: name,
      phones: phones,
      emails: emails,
      organization: org,
      jobTitle: title,
      address: adr,
      website: url,
      note: note,
    );
  }

  static KitoScanPayment? _payment(String text) {
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    final q = {
      for (final e in uri.queryParameters.entries) e.key.toLowerCase(): e.value,
    };
    final path = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final kindText =
        (uri.host.isNotEmpty
                ? uri.host
                : q['type'] ?? (path.isEmpty ? '' : path.first))
            .toLowerCase();
    final kind =
        KitoScanPaymentKind.values.where((k) => k.name == kindText).firstOrNull;
    if (kind == null) return null;
    final number = (q['number'] ??
            path.lastWhere(
              (s) => s.toLowerCase() != kindText,
              orElse: () => '',
            ))
        .replaceAll(' ', '');
    if (number.isEmpty || !RegExp(r'^\+?\d+$').hasMatch(number)) return null;
    final amount = double.tryParse(q['amount'] ?? '');
    String? nonEmpty(String? v) =>
        v == null || v.trim().isEmpty ? null : v.trim();
    return KitoScanPayment(
      kind: kind,
      number: number,
      account: nonEmpty(q['account']),
      amount: amount == null || amount <= 0 ? null : (amount * 100).round(),
      currency: (nonEmpty(q['currency']) ?? 'KES').toUpperCase(),
      merchant: nonEmpty(q['name']),
      note: nonEmpty(q['note']),
    );
  }

  static String? _phone(String text) {
    final v = Uri.decodeComponent(text).trim();
    if (!RegExp(r'^[\d +\-().]+$').hasMatch(v)) return null;
    final digits = v.replaceAll(RegExp(r'\D'), '').length;
    return digits >= 3 && digits <= 15 ? v : null;
  }

  static KitoScanGeo? _geo(String text) {
    final body = text.substring(4);
    final parts = body.split('?');
    final coords = parts.first.split(',');
    if (coords.length < 2) return null;
    final lat = double.tryParse(coords[0].trim());
    final lng = double.tryParse(coords[1].split(';').first.trim());
    if (lat == null || lng == null || lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    String? query;
    if (parts.length > 1) {
      final q = Uri.splitQueryString(parts[1])['q'];
      if (q != null && q.isNotEmpty) query = q;
    }
    return KitoScanGeo(lat, lng, query: query);
  }

  static Uri? _url(String text) {
    if (text.contains(' ')) return null;
    final lower = text.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final u = Uri.tryParse(text);
      return u != null && u.host.isNotEmpty ? u : null;
    }
    if (lower.startsWith('www.') ||
        RegExp(
          r'^[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}(/\S*)?$',
        ).hasMatch(lower)) {
      final u = Uri.tryParse('https://$text');
      return u != null && u.host.contains('.') ? u : null;
    }
    return null;
  }
}

/// Check-digit maths for product barcodes (GS1 mod 10) and card numbers (Luhn).
abstract final class KitoScanCheckDigits {
  /// The GS1 check digit for [body] (the digits before it).
  static int? gtinCheckDigit(String body) {
    if (body.isEmpty || !RegExp(r'^\d+$').hasMatch(body)) return null;
    var sum = 0;
    for (var i = 0; i < body.length; i++) {
      final d = body.codeUnitAt(body.length - 1 - i) - 48;
      sum += d * (i.isEven ? 3 : 1);
    }
    return (10 - sum % 10) % 10;
  }

  /// Whether an 8, 12, 13 or 14 digit GTIN ends in the right check digit.
  static bool isValidGtin(String code) {
    if (![8, 12, 13, 14].contains(code.length)) return false;
    final expected = gtinCheckDigit(code.substring(0, code.length - 1));
    return expected != null &&
        code.codeUnitAt(code.length - 1) - 48 == expected;
  }

  /// Expands an 8-digit UPC-E to its 12-digit UPC-A.
  static String? expandUpcE(String code) {
    if (code.length != 8 || !RegExp(r'^[01]\d{7}$').hasMatch(code)) return null;
    final d = [for (var i = 1; i <= 6; i++) code[i]];
    final body = switch (d[5]) {
      '0' ||
      '1' ||
      '2' => [d[0], d[1], d[5], '0', '0', '0', '0', d[2], d[3], d[4]],
      '3' => [d[0], d[1], d[2], '0', '0', '0', '0', '0', d[3], d[4]],
      '4' => [d[0], d[1], d[2], d[3], '0', '0', '0', '0', '0', d[4]],
      _ => [d[0], d[1], d[2], d[3], d[4], '0', '0', '0', '0', d[5]],
    };
    return '${code[0]}${body.join()}${code[7]}';
  }

  /// Whether a UPC-E's check digit matches its expansion.
  static bool isValidUpcE(String code) {
    final e = expandUpcE(code);
    return e != null && isValidGtin(e);
  }

  /// The Luhn check for card numbers; ignores spaces and dashes.
  static bool isValidLuhn(String number) {
    final cleaned = number.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length < 2 || !RegExp(r'^\d+$').hasMatch(cleaned)) return false;
    var sum = 0;
    for (var i = 0; i < cleaned.length; i++) {
      var d = cleaned.codeUnitAt(cleaned.length - 1 - i) - 48;
      if (i.isOdd) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
    }
    return sum % 10 == 0;
  }
}
