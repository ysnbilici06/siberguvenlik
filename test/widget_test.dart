import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siber_kalkan/ekranlar/alistirma.dart';
import 'package:siber_kalkan/ekranlar/araclar.dart';
import 'package:siber_kalkan/ekranlar/ogren.dart';
import 'package:siber_kalkan/ekranlar/ortak.dart';
import 'package:siber_kalkan/ekranlar/profil.dart';
import 'package:siber_kalkan/main.dart';
import 'package:siber_kalkan/veri/depo.dart';
import 'package:siber_kalkan/veri/modeller.dart';
import 'package:siber_kalkan/veri/parola.dart';
import 'package:siber_kalkan/veri/profil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final d = Depo.i;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await d.baslat();
  });

  group('içerik', () {
    test('beklenen bölümler dolu', () {
      expect(d.konular.length, 10);
      expect(d.sorular.length, 60);
      expect(d.senaryolar.length, 20);
      expect(d.listeler, isNotEmpty);
      expect(d.rehberler, isNotEmpty);
      expect(d.ipuclari, isNotEmpty);
    });

    test('kimlikler tekrarsız', () {
      void tekrarsiz(Iterable<String> idler) => expect(idler.toSet().length, idler.length, reason: '$idler');
      tekrarsiz(d.konular.map((e) => e.id));
      tekrarsiz(d.sorular.map((e) => e.id));
      tekrarsiz(d.senaryolar.map((e) => e.id));
      tekrarsiz(d.listeler.map((e) => e.id));
      tekrarsiz(d.rehberler.map((e) => e.id));
      for (final l in d.listeler) {
        tekrarsiz(l.maddeler.map((e) => e.id));
      }
    });

    test('ikon ve renk adları tanımlı', () {
      for (final (ikon, renk) in [
        for (final e in d.konular) (e.ikon, e.renk),
        for (final e in d.listeler) (e.ikon, e.renk),
        for (final e in d.rehberler) (e.ikon, e.renk),
      ]) {
        expect(ikonlar, contains(ikon));
        expect(renkler, contains(renk));
      }
    });

    test('her konunun metni ve testi var', () {
      for (final k in d.konular) {
        expect(k.metin, isNotEmpty, reason: k.id);
        expect(k.yap, isNotEmpty, reason: k.id);
        expect(k.yapma, isNotEmpty, reason: k.id);
        expect(d.konuSorulari(k.id).length, 6, reason: k.id);
      }
    });

    test('sorular var olan konuya bağlı ve doğru cevap seçeneklerin içinde', () {
      for (final s in d.sorular) {
        expect(d.konu(s.konu), isNotNull, reason: s.id);
        expect(s.secenekler.length, 4, reason: s.id);
        expect(s.secenekler.toSet().length, 4, reason: s.id);
        expect(s.dogru, inInclusiveRange(0, 3), reason: s.id);
        expect(s.aciklama, isNotEmpty, reason: s.id);
      }
    });

    test('doğru cevap hep aynı sırada değil', () {
      final siralar = {for (final s in d.sorular) s.dogru};
      expect(siralar, {0, 1, 2, 3});
    });

    test('senaryolar var olan konuya bağlı ve işaretleri iletide geçiyor', () {
      for (final s in d.senaryolar) {
        expect(d.konu(s.konu), isNotNull, reason: s.id);
        expect(Senaryo.turler, contains(s.tur), reason: s.id);
        expect(s.isaretler, isNotEmpty, reason: s.id);
        final tumu = '${s.gonderen}\n${s.baslik}\n${s.metin}';
        for (final i in s.isaretler) {
          expect(tumu, contains(i.parca), reason: s.id);
        }
      }
      expect(d.senaryolar.where((s) => s.tuzak), isNotEmpty);
      expect(d.senaryolar.where((s) => !s.tuzak), isNotEmpty);
    });

    test('örneklerdeki adresler kurgusal alan adı kullanıyor', () {
      final adres = RegExp(r'https?://[^\s/]+');
      for (final s in d.senaryolar) {
        for (final m in adres.allMatches(s.metin)) {
          final a = m[0]!;
          expect(a.endsWith('.example') || a.contains('198.51.100.'), isTrue, reason: '${s.id}: $a');
        }
      }
    });

    test('rehberler var olan ve kaynağı belli kanallara bağlı', () {
      for (final r in d.rehberler) {
        expect(r.adimlar, isNotEmpty, reason: r.id);
        expect(r.kanallar, isNotEmpty, reason: r.id);
        for (final k in r.kanallar) {
          expect(d.kanallar, contains(k), reason: r.id);
        }
      }
      for (final k in d.kanallar.values) {
        expect(k.kaynak, startsWith('https://'), reason: k.ad);
      }
    });
  });

  group('profil', () {
    test('il listesi ve konulardaki yaş grupları geçerli', () {
      expect(iller.length, 81);
      expect(iller.toSet().length, 81);
      for (final k in d.konular) {
        for (final y in k.yas) {
          expect(yasGruplari, contains(y), reason: k.id);
        }
      }
    });

    test('kaydedilir, yeniden açılışta korunur, silinince ilerleme kalır', () async {
      expect(d.karsilandi, isFalse);
      expect(d.profilVar, isFalse);
      await d.soruCevapla(d.sorular.first.id, true);
      await d.profilKaydet(ad: '  Ayşe ', yas: '30-49', sehir: 'Trabzon');
      await d.baslat();
      expect((d.ad, d.yas, d.sehir, d.karsilandi), ('Ayşe', '30-49', 'Trabzon', true));

      await d.profilSil();
      await d.baslat();
      expect(d.profilVar, isFalse);
      expect(d.karsilandi, isTrue);
      expect(d.dogruSoru, 1);
    });

    test('bilinmeyen yaş grubu ve il kabul edilmez, uzun ad kırpılır', () async {
      await d.profilKaydet(ad: 'a' * 80, yas: '200', sehir: 'Atlantis');
      expect((d.ad.length, d.yas, d.sehir), (adSiniri, null, null));
    });

    test('atlamak profil oluşturmaz', () async {
      await d.karsilamayiGec();
      await d.baslat();
      expect((d.karsilandi, d.profilVar), (true, false));
    });

    test('yaş grubuna önerilen konular okundukça listeden çıkar', () async {
      expect(d.onerilenKonular, isEmpty);
      await d.profilKaydet(ad: '', yas: '65+');
      final onerilen = d.onerilenKonular.map((k) => k.id).toList();
      expect(onerilen, containsAll(['dolandiricilik', 'sosyal-muhendislik']));
      await d.okunduYap('dolandiricilik', true);
      expect(d.onerilenKonular.map((k) => k.id), isNot(contains('dolandiricilik')));
    });

    test('kişisel iletiler ad ve şehirle doldurulur, işaretleri iletide geçer', () {
      final kisisel = d.senaryolar.where((s) => s.kisiselMetin != null).toList();
      expect(kisisel.where((s) => s.tuzak), isNotEmpty);
      expect(kisisel.where((s) => !s.tuzak), isNotEmpty);
      for (final s in kisisel) {
        final u = s.uyarla(ad: 'Ayşe', sehir: 'Trabzon');
        expect(u.kisisel, isTrue, reason: s.id);
        expect(u.metin, contains('Ayşe'), reason: s.id);
        expect((u.id, u.tuzak, u.aciklama), (s.id, s.tuzak, s.aciklama));
        final tumu = '${u.gonderen}\n${u.baslik}\n${u.metin}';
        expect(tumu, isNot(contains('{')), reason: s.id);
        expect(u.isaretler, isNotEmpty, reason: s.id);
        for (final i in u.isaretler) {
          expect(tumu, contains(i.parca), reason: s.id);
          expect(i.aciklama, isNot(contains('{')), reason: s.id);
        }
      }
    });

    test('bilgi eksikse ileti genel hâliyle kalır', () {
      final kargo = d.senaryolar.firstWhere((s) => s.id == 'kargo-sms');
      expect(kargo.uyarla(ad: '', sehir: '').metin, kargo.metin);
      // Şehir de isteyen ileti yalnızca adla kişiselleştirilmez.
      expect(kargo.uyarla(ad: 'Ayşe', sehir: '').kisisel, isFalse);
      // Yalnızca ad isteyen ileti adla kişiselleşir.
      final borc = d.senaryolar.firstWhere((s) => s.id == 'apk-sms');
      expect(borc.uyarla(ad: 'Ayşe', sehir: '').metin, startsWith('Sayın Ayşe,'));
      // Kişisel biçimi olmayan ileti hiç değişmez.
      final adres = d.senaryolar.firstWhere((s) => s.tur == 'adres');
      expect(identical(adres.uyarla(ad: 'Ayşe', sehir: 'Trabzon'), adres), isTrue);
    });

    test('ad içindeki yer tutucu yeniden işlenmez', () {
      final borc = d.senaryolar.firstWhere((s) => s.id == 'apk-sms');
      expect(borc.uyarla(ad: '{sehir}', sehir: 'Trabzon').metin, startsWith('Sayın {sehir},'));
    });

    test('sıradaki senaryolar profille kişiselleşir', () async {
      expect(d.siradakiSenaryolar(20).where((s) => s.kisisel), isEmpty);
      await d.profilKaydet(ad: 'Ayşe', sehir: 'Trabzon');
      expect(d.siradakiSenaryolar(20).where((s) => s.kisisel).length, d.senaryolar.where((s) => s.kisiselMetin != null).length);
    });
  });

  group('ilerleme', () {
    test('kaydedilir ve yeniden açılışta korunur', () async {
      final soru = d.sorular.first;
      final senaryo = d.senaryolar.first;
      final liste = d.listeler.first;
      await d.soruCevapla(soru.id, true);
      await d.senaryoCevapla(senaryo.id, false);
      await d.okunduYap(soru.konu, true);
      await d.isaretle(liste.id, liste.maddeler.first.id, true);

      // setUp'taki boş kayıt yerine az önce yazılanı okur.
      await d.baslat();
      expect(d.soruSonucu(soru.id), isTrue);
      expect(d.senaryoSonucu(senaryo.id), isFalse);
      expect(d.okundu(soru.konu), isTrue);
      expect(d.isaretliSayisi(liste), 1);
      expect(d.dogruSoru, 1);
      expect(d.okunanKonu, 1);
      expect(d.listeOrani, greaterThan(0));

      await d.sifirla();
      expect(d.cozulenSoru, 0);
      expect(d.listeOrani, 0);
    });

    test('karışık test önce çözülmeyenleri, sonra yanlışları getirir', () async {
      for (final s in d.sorular.skip(2)) {
        await d.soruCevapla(s.id, true);
      }
      await d.soruCevapla(d.sorular[1].id, false);
      final secilen = d.testSorulari(3).map((s) => s.id).toList();
      expect(secilen.take(2), [d.sorular[0].id, d.sorular[1].id]);
    });

    test('bozuk kayıt açılışı engellemez', () async {
      SharedPreferences.setMockInitialValues({'durum': '{bozuk'});
      await d.baslat();
      expect(d.cozulenSoru, 0);
    });
  });

  group('parola', () {
    test('yaygın parolalar çok zayıf', () {
      for (final p in ['123456', 'password', 'Sifre123', 'qwerty', 'Galatasaray1905', 'şifre']) {
        expect(parolaDegerlendir(p).duzey, ParolaDuzeyi.cokZayif, reason: p);
      }
    });

    test('kısa ve kalıplı parolalar zayıf kalır', () {
      expect(parolaDegerlendir('aaaaaaaaaaaa').duzey, ParolaDuzeyi.cokZayif);
      expect(parolaDegerlendir('abcdefgh').duzey, ParolaDuzeyi.cokZayif);
      expect(parolaDegerlendir('Kx7!p').duzey.index, lessThanOrEqualTo(ParolaDuzeyi.zayif.index));
      expect(parolaDegerlendir('ahmet1987').uyarilar, contains(contains('Doğum yılı')));
    });

    test('uzun parola cümlesi ve rastgele parola güçlü', () {
      expect(parolaDegerlendir('mavi-kaplan-sessiz-ırmak-bulut').duzey.index, greaterThanOrEqualTo(ParolaDuzeyi.guclu.index));
      expect(parolaDegerlendir(parolaUret(uzunluk: 20)).duzey.index, greaterThanOrEqualTo(ParolaDuzeyi.guclu.index));
    });

    test('uzunluk arttıkça tahmin gücü artar', () {
      expect(parolaDegerlendir('kTr9#mQz2!vL').bit, greaterThan(parolaDegerlendir('kTr9#mQz').bit));
    });

    test('üretici uzunluğa ve seçilen kümelere uyar', () {
      final r = Random(7);
      for (var n = 0; n < 50; n++) {
        final p = parolaUret(uzunluk: 12, rastgele: r);
        expect(p.length, 12);
        expect(p, matches(RegExp(r'[a-z]')));
        expect(p, matches(RegExp(r'[A-Z]')));
        expect(p, matches(RegExp(r'[0-9]')));
        expect(p, matches(RegExp(r'[^a-zA-Z0-9]')));
      }
      expect(parolaUret(uzunluk: 30, buyuk: false, rakam: false, simge: false, rastgele: r), matches(RegExp(r'^[a-z]{30}$')));
      expect(parolaUret(uzunluk: 10, kucuk: false, buyuk: false, simge: false, rastgele: r), matches(RegExp(r'^[0-9]{10}$')));
    });

    test('parola cümlesi listeden seçilir', () {
      expect(kelimeListesi.length, greaterThanOrEqualTo(256));
      final kelimeler = parolaCumlesiUret(kelime: 7, rastgele: Random(3)).split('-');
      expect(kelimeler.length, 7);
      expect(kelimeListesi, containsAll(kelimeler));
      expect(cumleBiti(7), greaterThan(cumleBiti(6)));
    });
  });

  test('isaretliMetin eşleşen parçaları ayırır', () {
    final span = isaretliMetin('hemen tıklayın: hemen', ['hemen', 'yok'], zemin: Colors.red);
    expect(span.toPlainText(), 'hemen tıklayın: hemen');
    expect(span.children!.where((s) => (s as TextSpan).style?.backgroundColor != null).length, 2);
  });

  group('arayüz', () {
    // Dar bir telefon; taşma olursa test hata verir.
    Future<void> ac(WidgetTester tester, Widget ekran) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Yeni anahtar, art arda açılan aynı türden sayfaların önceki durumu taşımasını önler.
      await tester.pumpWidget(KeyedSubtree(key: UniqueKey(), child: ekran));
      await tester.pumpAndSettle();
    }

    // Liste ekran dışındaki öğeleri çizmez; aranan öğe görünene kadar kaydırır.
    Future<void> gor(WidgetTester tester, Finder aranan) async {
      await tester.scrollUntilVisible(aranan, 150, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
    }

    testWidgets('ilk açılışta karşılama doldurulur, sonra ana sayfa adla açılır', (tester) async {
      await ac(tester, const SiberKalkanUygulamasi());
      expect(find.text('Hoş geldiniz'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ayşe');
      await gor(tester, find.text('30–49'));
      await tester.tap(find.text('30–49'));
      await gor(tester, find.text('Kaydet'));
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      expect(find.text('Merhaba Ayşe'), findsOneWidget);
      expect((d.ad, d.yas, d.karsilandi), ('Ayşe', '30-49', true));
      await gor(tester, find.text('Yaş grubunuza önerilen konular'));

      // İkinci açılışta karşılama çıkmaz.
      await ac(tester, const SiberKalkanUygulamasi());
      expect(find.text('Hoş geldiniz'), findsNothing);
    });

    testWidgets('kişisel tuzakta ad iletide görünür ve cevaptan sonra açıklanır', (tester) async {
      await d.profilKaydet(ad: 'Ayşe', sehir: 'Trabzon');
      final s = d.uyarla(d.senaryolar.firstWhere((s) => s.id == 'kargo-sms'));
      await ac(tester, MaterialApp(home: SenaryoEkrani([s])));
      expect(find.textContaining('Sayın Ayşe, Trabzon', findRichText: true), findsOneWidget);
      await gor(tester, find.text('Tuzak'));
      await tester.tap(find.text('Tuzak'));
      await tester.pumpAndSettle();
      await gor(tester, find.text('Bu ileti size özeldi'));
    });

    testWidgets('bilgilerim ekranı açılır ve silme düğmesi çalışır', (tester) async {
      await d.profilKaydet(ad: 'Ayşe', yas: '18-29', sehir: 'Trabzon');
      await ac(tester, MaterialApp(home: Builder(builder: (c) => TextButton(onPressed: () => git(c, const ProfilEkrani()), child: const Text('aç')))));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.text('Trabzon'), findsOneWidget);
      await gor(tester, find.text('Bilgilerimi sil'));
      await tester.tap(find.text('Bilgilerimi sil'));
      await tester.pumpAndSettle();
      expect(d.profilVar, isFalse);
      expect(find.text('aç'), findsOneWidget);
    });

    testWidgets('dört sekme dar ekranda taşmadan açılır', (tester) async {
      await ac(tester, const SiberKalkanUygulamasi());
      await gor(tester, find.text('Atla'));
      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();
      expect(find.text('Günün ipucu'), findsOneWidget);
      for (final (sekme, beklenen) in [
        ('Öğren', d.konular.first.baslik),
        ('Alıştırma', 'Karışık test'),
        ('Araçlar', 'Parola Üretici'),
      ]) {
        await tester.tap(find.widgetWithText(NavigationDestination, sekme));
        await tester.pumpAndSettle();
        expect(find.text(beklenen), findsWidgets);
      }
    });

    testWidgets('her konu sayfası açılır', (tester) async {
      for (final k in d.konular) {
        await ac(tester, MaterialApp(home: KonuDetay(k)));
        expect(find.text(k.metin.first), findsOneWidget);
      }
    });

    testWidgets('testte cevap kaydedilir ve açıklama görünür', (tester) async {
      final soru = d.sorular.first;
      await ac(tester, MaterialApp(home: TestEkrani([soru])));
      await gor(tester, find.text(soru.secenekler[soru.dogru]));
      await tester.tap(find.text(soru.secenekler[soru.dogru]));
      await tester.pumpAndSettle();
      expect(d.soruSonucu(soru.id), isTrue);
      await gor(tester, find.text(soru.aciklama));
      await gor(tester, find.text('Sonucu gör'));
      await tester.tap(find.text('Sonucu gör'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 1 doğru'), findsOneWidget);
    });

    testWidgets('her senaryo iki kararla da taşmadan çizilir', (tester) async {
      for (final s in d.senaryolar) {
        await ac(tester, MaterialApp(home: SenaryoEkrani([s])));
        final dugme = find.text(s.tuzak ? 'Tuzak' : 'Güvenli');
        await gor(tester, dugme);
        await tester.tap(dugme);
        await tester.pumpAndSettle();
        expect(d.senaryoSonucu(s.id), isTrue, reason: s.id);
        await gor(tester, find.text(s.aciklama));
        await gor(tester, find.text('Sonucu gör'));
      }
    });

    testWidgets('araç sayfaları açılır', (tester) async {
      await ac(tester, const MaterialApp(home: ParolaGucu()));
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      expect(find.text('Çok zayıf'), findsOneWidget);

      await ac(tester, const MaterialApp(home: ParolaUretici()));
      await tester.tap(find.text('Parola cümlesi'));
      await tester.pumpAndSettle();
      await gor(tester, find.textContaining('Kelime sayısı'));

      await ac(tester, const MaterialApp(home: KontrolListeleri()));
      expect(find.text(d.listeler.first.baslik), findsOneWidget);

      await ac(tester, const MaterialApp(home: MagdurRehberi()));
      expect(find.text(d.rehberler.first.baslik), findsOneWidget);
      for (final r in d.rehberler) {
        await ac(tester, MaterialApp(home: RehberDetay(r)));
        expect(find.text(r.adimlar.first), findsOneWidget);
      }
    });
  });
}
