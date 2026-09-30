// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 30/09/2026.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito_ui_wallet_cards/kito_ui_wallet_cards.dart';

void main() {
  group('brand detection', () {
    test('networks by prefix', () {
      const cases = {
        '4111 1111 1111 1111': KitoWalletCardBrand.visa,
        '5500 0000 0000 0004': KitoWalletCardBrand.mastercard,
        '2221 0000 0000 0009': KitoWalletCardBrand.mastercard,
        '3782 822463 10005': KitoWalletCardBrand.amex,
        '6011 1111 1111 1117': KitoWalletCardBrand.discover,
        '6500 0000 0000 0000': KitoWalletCardBrand.verve,
        '5061 0000 0000 0000': KitoWalletCardBrand.verve,
        '6200 0000 0000 0005': KitoWalletCardBrand.unionPay,
        '3530 1113 3330 0000': KitoWalletCardBrand.jcb,
        '3056 930902 5904': KitoWalletCardBrand.dinersClub,
        '9999': KitoWalletCardBrand.unknown,
        '': KitoWalletCardBrand.unknown,
      };
      cases.forEach((number, brand) {
        expect(KitoWalletCardNumber.brandOf(number), brand, reason: number);
      });
    });

    test('phone numbers are mobile money', () {
      for (final phone in [
        '0712 345 678',
        '0110 123 456',
        '+254 712 345 678',
        '254712345678'
      ]) {
        expect(KitoWalletCardNumber.brandOf(phone),
            KitoWalletCardBrand.mobileMoney,
            reason: phone);
      }
    });
  });

  group('formatting and masking', () {
    test('groups digits for the brand and cuts at its length', () {
      expect(KitoWalletCardNumber.format('4111111111111111999'),
          '4111 1111 1111 1111');
      expect(
          KitoWalletCardNumber.format('378282246310005'), '3782 822463 10005');
      expect(KitoWalletCardNumber.format('411'), '411');
      expect(KitoWalletCardNumber.format('+254712345678'), '0712 345 678');
      expect(KitoWalletCardNumber.format('5061000000000000123'),
          '5061 0000 0000 0000 123');
    });

    test('masks everything but the last four', () {
      expect(
          KitoWalletCardNumber.masked('4120', brand: KitoWalletCardBrand.visa),
          '•••• •••• •••• 4120');
      expect(
          KitoWalletCardNumber.masked('378282246310005',
              brand: KitoWalletCardBrand.amex),
          '•••• •••••• •0005');
      expect(KitoWalletCardNumber.short('4111111111114120'), '•••• 4120');
      expect(
          KitoWalletCardNumber.maskedPhone('+254 712 345 678'), '0712 ••• 678');
      expect(KitoWalletCardNumber.last4('4111 1111 1111 4120'), '4120');
    });

    test('Luhn and expiry', () {
      expect(KitoWalletCardNumber.isValid('4242 4242 4242 4242'), isTrue);
      expect(KitoWalletCardNumber.isValid('4242 4242 4242 4241'), isFalse);
      expect(KitoWalletCardNumber.isValid('4242'), isFalse);
      expect(KitoWalletCardNumber.formatExpiry('929'), '09/29');
      expect(KitoWalletCardNumber.formatExpiry('0929'), '09/29');
      final now = DateTime(2026, 9, 30);
      expect(KitoWalletCardNumber.isExpiryValid('09/26', now: now), isTrue);
      expect(KitoWalletCardNumber.isExpiryValid('08/26', now: now), isFalse);
      expect(KitoWalletCardNumber.isExpiryValid('13/30', now: now), isFalse);
    });

    test('input formatters keep the cursor after the typed digit', () {
      final number = KitoWalletCardNumberFormatter();
      final value = number.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
            text: '41111111', selection: TextSelection.collapsed(offset: 8)),
      );
      expect(value.text, '4111 1111');
      expect(value.selection.baseOffset, 9);
      final amex = number.formatEditUpdate(
          TextEditingValue.empty,
          const TextEditingValue(
              text: '3782822463',
              selection: TextSelection.collapsed(offset: 10)));
      expect(amex.text, '3782 822463');
      final card = KitoWalletCardNumberFormatter(allowsMobileMoney: false)
          .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(
                  text: '0712345678',
                  selection: TextSelection.collapsed(offset: 10)));
      expect(card.text, '0712 3456 78');

      final expiry = KitoWalletExpiryFormatter();
      expect(
          expiry
              .formatEditUpdate(
                  TextEditingValue.empty, const TextEditingValue(text: '092'))
              .text,
          '09/2');
      expect(
          expiry
              .formatEditUpdate(const TextEditingValue(text: '09/'),
                  const TextEditingValue(text: '09'))
              .text,
          '0');
    });
  });

  group('cards and money', () {
    test('a card from a full number keeps only the last four', () {
      final card = KitoWalletCard.fromNumber('4111 1111 1111 4120',
          name: 'Everyday',
          holder: 'Wycliff N',
          expiry: '09/29',
          balance: 7450);
      expect(card.brand, KitoWalletCardBrand.visa);
      expect(card.last4, '4120');
      expect(card.maskedNumber, '•••• •••• •••• 4120');
      expect(card.mark, KitoWalletCardMark.forBrand(KitoWalletCardBrand.visa));
      expect(card.formattedBalance, 'KES 7,450');
      expect(card.semanticLabel, 'Everyday Visa ending 4120');
      final renamed = card.copyWith(name: 'Daily', balance: 100);
      expect(renamed.id, card.id);
      expect(renamed.maskedNumber, card.maskedNumber);
      expect(renamed.name, 'Daily');
      expect(renamed, isNot(card));
      expect(card.copyWith(), card);
    });

    test('mobile money wallets mask the phone number', () {
      final wallet = KitoWalletCard.mobileMoney(
          phone: '0712345678', issuer: 'M-PESA', balance: 12450);
      expect(wallet.brand.isMobileMoney, isTrue);
      expect(wallet.maskedNumber, '0712 ••• 678');
      expect(wallet.shortNumber, '0712 ••• 678');
      expect(wallet.style, KitoWalletCardStyle.safari);
      expect(wallet.copyWith(name: 'Chama').maskedNumber, '0712 ••• 678');
      expect(wallet.semanticLabel, 'Mobile money M-PESA, 0712 ••• 678');
    });

    test('totals and money formatting', () {
      final cards = [
        KitoWalletCard(name: 'A', last4: '1111', balance: 1000.5),
        KitoWalletCard(name: 'B', last4: '2222', balance: 250),
      ];
      expect(cards.totalBalance, 1250.5);
      expect(KitoWalletMoney.format(1234567, 'KES'), 'KES 1,234,567');
      expect(KitoWalletMoney.format(1204.5, 'USD', decimals: 2), r'$1,204.50');
      expect(KitoWalletMoney.format(-12, 'EUR'), '−€12');
      expect(KitoWalletMoney.format(999, 'kes'), 'KES 999');
      expect(KitoWalletMoney.lerp(0, 100, 0.25), 25);
    });

    test('layout maths', () {
      expect(
          KitoWalletCardStack.offset(
              index: 2,
              selectedIndex: null,
              count: 4,
              peek: 58,
              cardHeight: 200,
              containerHeight: 600),
          116);
      expect(
          KitoWalletCardStack.offset(
              index: 1,
              selectedIndex: 1,
              count: 4,
              peek: 58,
              cardHeight: 200,
              containerHeight: 600),
          0);
      expect(
          KitoWalletCardStack.offset(
              index: 3,
              selectedIndex: 1,
              count: 4,
              peek: 58,
              cardHeight: 200,
              containerHeight: 600),
          600 - 64 - 16 + 16);
      expect([
        for (var i = 0; i < 5; i++)
          KitoWalletCardFan.angle(index: i, count: 5, spread: 9)
      ], [
        -18,
        -9,
        0,
        9,
        18
      ]);
      expect(
          KitoWalletPocket.cardOffset(
              index: 0, count: 3, cardHeight: 100, revealed: true),
          -62 - 40);
      expect(
          KitoWalletPocket.cardOffset(
              index: 2, count: 3, cardHeight: 100, revealed: false),
          -20);
    });
  });
}
