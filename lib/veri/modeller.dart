List<String> _metinler(Object? d) => [for (final e in (d as List? ?? const [])) e as String];

/// Öğren bölümündeki bir konu: kısa okuma, yapılacaklar, yapılmayacaklar ve konu testi.
class Konu {
  Konu.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        baslik = j['baslik'] as String,
        ozet = j['ozet'] as String,
        ikon = j['ikon'] as String,
        renk = j['renk'] as String,
        metin = _metinler(j['metin']),
        yap = _metinler(j['yap']),
        yapma = _metinler(j['yapma']),
        yas = _metinler(j['yas']);

  final String id;
  final String baslik;
  final String ozet;
  final String ikon;
  final String renk;
  final List<String> metin;
  final List<String> yap;
  final List<String> yapma;

  /// Konunun öncelikle önerildiği yaş grupları (`yasGruplari` anahtarları); boşsa kimseye özel önerilmez.
  final List<String> yas;
}

class Soru {
  Soru.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        konu = j['konu'] as String,
        soru = j['soru'] as String,
        secenekler = _metinler(j['secenekler']),
        dogru = j['dogru'] as int,
        aciklama = j['aciklama'] as String;

  final String id;
  final String konu;
  final String soru;
  final List<String> secenekler;

  /// Doğru seçeneğin [secenekler] içindeki sırası.
  final int dogru;
  final String aciklama;
}

/// Bir senaryoda dikkat edilmesi gereken yer: iletinin içinden bir parça ve neden önemli olduğu.
class Isaret {
  const Isaret(this.parca, this.aciklama);

  Isaret.fromJson(Map<String, dynamic> j)
      : parca = j['parca'] as String,
        aciklama = j['aciklama'] as String;

  /// Senaryonun gönderen, başlık ya da metninde harfi harfine geçen kesit.
  final String parca;
  final String aciklama;
}

/// "Gerçek mi, tuzak mı?" alıştırmasındaki kurgusal ileti.
class Senaryo {
  Senaryo.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        konu = j['konu'] as String,
        tur = j['tur'] as String,
        durum = j['durum'] as String? ?? '',
        gonderen = j['gonderen'] as String? ?? '',
        baslik = j['baslik'] as String? ?? '',
        metin = j['metin'] as String,
        tuzak = j['tuzak'] as bool,
        isaretler = _isaretler(j['isaretler']),
        aciklama = j['aciklama'] as String,
        kisiselMetin = (j['kisisel'] as Map<String, dynamic>?)?['metin'] as String?,
        kisiselIsaretler = _isaretler((j['kisisel'] as Map<String, dynamic>?)?['isaretler']),
        kisisel = false;

  Senaryo._kisisel(Senaryo s, this.metin, this.isaretler)
      : id = s.id,
        konu = s.konu,
        tur = s.tur,
        durum = s.durum,
        gonderen = s.gonderen,
        baslik = s.baslik,
        tuzak = s.tuzak,
        aciklama = s.aciklama,
        kisiselMetin = s.kisiselMetin,
        kisiselIsaretler = s.kisiselIsaretler,
        kisisel = true;

  static List<Isaret> _isaretler(Object? d) =>
      [for (final e in (d as List? ?? const [])) Isaret.fromJson(e as Map<String, dynamic>)];

  static const turler = {'sms', 'eposta', 'adres', 'arama'};

  /// Kişisel metinlerde kullanılabilen yer tutucular: `{ad}` ve `{sehir}`.
  static final yerTutucu = RegExp(r'\{(ad|sehir)\}');

  /// Kullanıcının verdiği ad ve şehirle doldurulmuş hâli. Kişisel biçimi olmayan ya da
  /// gereken bilgisi eksik olan senaryo olduğu gibi döner.
  Senaryo uyarla({required String ad, required String sehir}) {
    final sablon = kisiselMetin;
    if (sablon == null) return this;
    final degerler = {'ad': ad, 'sehir': sehir};
    final metinler = [sablon, for (final i in kisiselIsaretler) ...[i.parca, i.aciklama]];
    for (final m in metinler) {
      if (yerTutucu.allMatches(m).any((e) => degerler[e[1]]!.isEmpty)) return this;
    }
    // Tek geçişte doldurulur; kullanıcının yazdığı ad içindeki "{sehir}" yeniden işlenmez.
    String doldur(String m) => m.replaceAllMapped(yerTutucu, (e) => degerler[e[1]]!);
    return Senaryo._kisisel(this, doldur(sablon), [for (final i in kisiselIsaretler) Isaret(doldur(i.parca), doldur(i.aciklama))]);
  }

  final String id;
  final String konu;

  /// [turler]den biri; iletinin nasıl çizileceğini belirler.
  final String tur;

  /// İletiyi alan kişinin o andaki durumu ("Kargo beklemiyorsunuz." gibi).
  final String durum;
  final String gonderen;
  final String baslik;
  final String metin;
  final bool tuzak;
  final List<Isaret> isaretler;
  final String aciklama;

  /// `{ad}` / `{sehir}` yer tutuculu biçim; yoksa senaryo kişiselleştirilmez.
  final String? kisiselMetin;
  final List<Isaret> kisiselIsaretler;

  /// [uyarla] ile kullanıcının bilgileri yerleştirilmişse true.
  final bool kisisel;
}

class ListeMaddesi {
  ListeMaddesi.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        metin = j['metin'] as String;

  final String id;
  final String metin;
}

class KontrolListesi {
  KontrolListesi.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        baslik = j['baslik'] as String,
        ikon = j['ikon'] as String,
        renk = j['renk'] as String,
        maddeler = [for (final e in j['maddeler'] as List) ListeMaddesi.fromJson(e as Map<String, dynamic>)];

  final String id;
  final String baslik;
  final String ikon;
  final String renk;
  final List<ListeMaddesi> maddeler;
}

/// Resmî bir başvuru kanalı. [kaynak], bilginin doğrulandığı resmî sayfadır.
class Kanal {
  Kanal.fromJson(Map<String, dynamic> j)
      : ad = j['ad'] as String,
        deger = j['deger'] as String,
        aciklama = j['aciklama'] as String? ?? '',
        kaynak = j['kaynak'] as String;

  final String ad;
  final String deger;
  final String aciklama;
  final String kaynak;
}

/// "Mağdur oldum" bölümündeki adım adım rehber.
class Rehber {
  Rehber.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        baslik = j['baslik'] as String,
        ozet = j['ozet'] as String,
        ikon = j['ikon'] as String,
        renk = j['renk'] as String,
        adimlar = _metinler(j['adimlar']),
        kanallar = _metinler(j['kanallar']);

  final String id;
  final String baslik;
  final String ozet;
  final String ikon;
  final String renk;
  final List<String> adimlar;

  /// İçerikteki `kanallar` sözlüğünün anahtarları.
  final List<String> kanallar;
}
