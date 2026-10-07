import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'modeller.dart';
import 'profil.dart';

/// Yüklenen içeriği, kullanıcının ilerlemesini ve isteğe bağlı profilini tutan tek kaynak.
/// Hepsi SharedPreferences'ta tek bir JSON olarak saklanır ve cihazdan çıkmaz.
class Depo extends ChangeNotifier {
  Depo._();
  static final Depo i = Depo._();

  static const _anahtar = 'durum';

  List<String> ipuclari = [];
  List<Konu> konular = [];
  List<Soru> sorular = [];
  List<Senaryo> senaryolar = [];
  List<KontrolListesi> listeler = [];
  List<Rehber> rehberler = [];
  Map<String, Kanal> kanallar = {};

  final Set<String> _okunan = {};
  final Map<String, bool> _soruSonucu = {};
  final Map<String, bool> _senaryoSonucu = {};
  final Set<String> _isaretli = {};

  /// Karşılama ekranı görüldüyse (doldurularak ya da atlanarak) true.
  bool karsilandi = false;

  // Profil: hepsi isteğe bağlı, yalnızca örnek iletileri ve konu önerilerini kişiselleştirmek için.
  String ad = '';
  String? yas;
  String? sehir;

  Future<void> baslat() async {
    icerigiYukle(await rootBundle.loadString('assets/veri/icerik.json'));
    final p = await SharedPreferences.getInstance();
    _durumuYukle(p.getString(_anahtar));
    notifyListeners();
  }

  void icerigiYukle(String ham) {
    final j = jsonDecode(ham) as Map<String, dynamic>;
    List<T> liste<T>(String ad, T Function(Map<String, dynamic>) kur) =>
        [for (final e in j[ad] as List) kur(e as Map<String, dynamic>)];
    ipuclari = [for (final e in j['ipuclari'] as List) e as String];
    konular = liste('konular', Konu.fromJson);
    sorular = liste('sorular', Soru.fromJson);
    senaryolar = liste('senaryolar', Senaryo.fromJson);
    listeler = liste('listeler', KontrolListesi.fromJson);
    rehberler = liste('rehberler', Rehber.fromJson);
    kanallar = {
      for (final e in (j['kanallar'] as Map<String, dynamic>).entries) e.key: Kanal.fromJson(e.value as Map<String, dynamic>),
    };
  }

  void _ilerlemeyiTemizle() {
    _okunan.clear();
    _soruSonucu.clear();
    _senaryoSonucu.clear();
    _isaretli.clear();
  }

  void _profiliTemizle() {
    ad = '';
    yas = null;
    sehir = null;
  }

  void _durumuYukle(String? ham) {
    _ilerlemeyiTemizle();
    _profiliTemizle();
    karsilandi = false;
    if (ham == null) return;
    try {
      final j = jsonDecode(ham) as Map<String, dynamic>;
      _okunan.addAll((j['okunan'] as List? ?? const []).cast<String>());
      _soruSonucu.addAll((j['sorular'] as Map<String, dynamic>? ?? const {}).cast<String, bool>());
      _senaryoSonucu.addAll((j['senaryolar'] as Map<String, dynamic>? ?? const {}).cast<String, bool>());
      _isaretli.addAll((j['isaretli'] as List? ?? const []).cast<String>());
      final p = j['profil'] as Map<String, dynamic>? ?? const {};
      _profiliAta(p['ad'] as String? ?? '', p['yas'] as String?, p['sehir'] as String?);
      karsilandi = j['karsilandi'] as bool? ?? false;
    } on Object {
      // Bozuk kayıt ilerlemeyi ve profili sıfırlar; uygulamanın açılmasını engellemez.
      _ilerlemeyiTemizle();
      _profiliTemizle();
      karsilandi = false;
    }
  }

  /// Bilinmeyen yaş grubu ya da il kabul edilmez; ad kırpılır ve [adSiniri] ile sınırlanır.
  void _profiliAta(String yeniAd, String? yeniYas, String? yeniSehir) {
    final kirpik = yeniAd.trim();
    ad = kirpik.length > adSiniri ? kirpik.substring(0, adSiniri) : kirpik;
    yas = yasGruplari.containsKey(yeniYas) ? yeniYas : null;
    sehir = iller.contains(yeniSehir) ? yeniSehir : null;
  }

  Future<void> _kaydet() async {
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _anahtar,
      jsonEncode({
        'okunan': _okunan.toList(),
        'sorular': _soruSonucu,
        'senaryolar': _senaryoSonucu,
        'isaretli': _isaretli.toList(),
        'karsilandi': karsilandi,
        'profil': {'ad': ad, 'yas': yas, 'sehir': sehir},
      }),
    );
  }

  // Profil

  bool get profilVar => ad.isNotEmpty || yas != null || sehir != null;

  Future<void> profilKaydet({required String ad, String? yas, String? sehir}) {
    _profiliAta(ad, yas, sehir);
    karsilandi = true;
    return _kaydet();
  }

  Future<void> profilSil() {
    _profiliTemizle();
    return _kaydet();
  }

  Future<void> karsilamayiGec() {
    karsilandi = true;
    return _kaydet();
  }

  /// Senaryonun, kullanıcının adı ve şehriyle doldurulmuş hâli (bilgi yoksa olduğu gibi).
  Senaryo uyarla(Senaryo s) => s.uyarla(ad: ad, sehir: sehir ?? '');

  /// Kullanıcının yaş grubuna önerilen, henüz okunmamış konular.
  List<Konu> get onerilenKonular => [for (final k in konular) if (k.yas.contains(yas) && !okundu(k.id)) k];

  // Konular

  bool okundu(String konuId) => _okunan.contains(konuId);

  Future<void> okunduYap(String konuId, bool deger) {
    deger ? _okunan.add(konuId) : _okunan.remove(konuId);
    return _kaydet();
  }

  int get okunanKonu => konular.where((k) => okundu(k.id)).length;

  List<Soru> konuSorulari(String konuId) => [for (final s in sorular) if (s.konu == konuId) s];

  Konu? konu(String id) {
    for (final k in konular) {
      if (k.id == id) return k;
    }
    return null;
  }

  // Test

  /// Sorunun son cevabı: doğruysa true, yanlışsa false, hiç çözülmediyse null.
  bool? soruSonucu(String soruId) => _soruSonucu[soruId];

  Future<void> soruCevapla(String soruId, bool dogru) {
    _soruSonucu[soruId] = dogru;
    return _kaydet();
  }

  int get cozulenSoru => sorular.where((s) => _soruSonucu.containsKey(s.id)).length;
  int get dogruSoru => sorular.where((s) => _soruSonucu[s.id] == true).length;

  /// Karışık test için [adet] soru: önce hiç çözülmeyenler, sonra yanlış yapılanlar, en son doğru bilinenler.
  List<Soru> testSorulari(int adet) => _oncelikli(sorular, (s) => _soruSonucu[s.id]).take(adet).toList();

  // Senaryolar

  bool? senaryoSonucu(String id) => _senaryoSonucu[id];

  Future<void> senaryoCevapla(String id, bool dogru) {
    _senaryoSonucu[id] = dogru;
    return _kaydet();
  }

  int get cozulenSenaryo => senaryolar.where((s) => _senaryoSonucu.containsKey(s.id)).length;
  int get dogruSenaryo => senaryolar.where((s) => _senaryoSonucu[s.id] == true).length;

  /// Sıradaki [adet] senaryo; profil varsa kişiselleştirilmiş hâlleriyle.
  List<Senaryo> siradakiSenaryolar(int adet) =>
      _oncelikli(senaryolar, (s) => _senaryoSonucu[s.id]).take(adet).map(uyarla).toList();

  List<T> _oncelikli<T>(List<T> hepsi, bool? Function(T) sonuc) {
    List<T> grup(bool? deger) => [for (final e in hepsi) if (sonuc(e) == deger) e]..shuffle();
    return [...grup(null), ...grup(false), ...grup(true)];
  }

  // Kontrol listeleri

  bool isaretli(String listeId, String maddeId) => _isaretli.contains('$listeId:$maddeId');

  Future<void> isaretle(String listeId, String maddeId, bool deger) {
    final a = '$listeId:$maddeId';
    deger ? _isaretli.add(a) : _isaretli.remove(a);
    return _kaydet();
  }

  int isaretliSayisi(KontrolListesi l) => l.maddeler.where((m) => isaretli(l.id, m.id)).length;

  /// Tüm kontrol listelerindeki işaretli maddelerin oranı (0–1).
  double get listeOrani {
    final toplam = listeler.fold(0, (t, l) => t + l.maddeler.length);
    if (toplam == 0) return 0;
    return listeler.fold(0, (t, l) => t + isaretliSayisi(l)) / toplam;
  }

  /// Yalnızca ilerlemeyi siler; profil [profilSil] ile ayrıca silinir.
  Future<void> sifirla() {
    _ilerlemeyiTemizle();
    return _kaydet();
  }
}
