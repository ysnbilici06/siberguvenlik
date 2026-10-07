import 'dart:math';

enum ParolaDuzeyi {
  cokZayif('Çok zayıf'),
  zayif('Zayıf'),
  orta('Orta'),
  guclu('Güçlü'),
  cokGuclu('Çok güçlü');

  const ParolaDuzeyi(this.ad);
  final String ad;
}

class ParolaSonucu {
  const ParolaSonucu(this.duzey, this.bit, this.uyarilar);
  final ParolaDuzeyi duzey;

  /// Kaba tahmin gücü (bit). Kesin bir ölçüm değil, karşılaştırma içindir.
  final double bit;
  final List<String> uyarilar;
}

const _kucuk = 'abcdefghijklmnopqrstuvwxyz';
const _buyuk = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _rakam = '0123456789';
const _simge = r'!@#$%&*?-_+=.';

const _klavyeDizileri = ['qwerty', 'asdfgh', 'zxcvbn', 'qazwsx', '1q2w3e'];

/// En sık kullanılan parolalardan küçük bir örnek; hepsi [_sade] biçiminde yazılır.
const _yayginParolalar = {
  '123456', '1234567', '12345678', '123456789', '1234567890', '12345', '1234', '111111', '000000', '121212',
  '123123', '654321', '666666', '112233', '123321', '987654321', 'password', 'password1', 'qwerty', 'qwerty123',
  'qwertyuiop', 'abc123', 'iloveyou', 'admin', 'welcome', 'letmein', 'monkey', 'dragon', 'master', 'login',
  '1q2w3e4r', '1q2w3e', 'asdfgh', 'asdfghjkl', 'zxcvbnm', 'qazwsx', 'sifre', 'sifrem', 'parola', 'parolam',
  'galatasaray', 'fenerbahce', 'besiktas', 'trabzonspor', 'istanbul', 'ankara', 'izmir', 'turkiye', 'askim',
  'canim', 'seniseviyorum', 'bebegim', 'merhaba', 'deneme',
};

/// Türkçe harfleri sadeleştirip küçültür: "Şifre" → "sifre".
String _sade(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

/// Parolanın gücünü yalnızca cihazda, hiçbir yere göndermeden tahmin eder.
ParolaSonucu parolaDegerlendir(String parola) {
  if (parola.isEmpty) return const ParolaSonucu(ParolaDuzeyi.cokZayif, 0, []);

  final sade = _sade(parola);
  // Sondaki rakam ve simgeler atılır: "Sifre123!" de "sifre" kadar tahmin edilebilirdir.
  final govde = sade.replaceAll(RegExp(r'[^a-z]+$'), '');
  if (_yayginParolalar.contains(sade) || (govde.length >= 4 && _yayginParolalar.contains(govde))) {
    return const ParolaSonucu(ParolaDuzeyi.cokZayif, 0, [
      'Bu parola ya da çok benzeri, en sık kullanılan parolalar arasında; ilk denenenlerden biridir.',
    ]);
  }

  final uyarilar = <String>[];
  final kucukVar = RegExp(r'[a-zçğıöşü]').hasMatch(parola);
  final buyukVar = RegExp(r'[A-ZÇĞİÖŞÜ]').hasMatch(parola);
  final rakamVar = RegExp(r'[0-9]').hasMatch(parola);
  final simgeVar = RegExp(r'[^a-zA-Z0-9çğıöşüÇĞİÖŞÜ]').hasMatch(parola);
  final havuz = (kucukVar ? 26 : 0) + (buyukVar ? 26 : 0) + (rakamVar ? 10 : 0) + (simgeVar ? 32 : 0);

  // Bir öncekiyle aynı ya da ardışık olan karakter (aaa, 123, abc) neredeyse hiç güç katmaz.
  final kodlar = parola.codeUnits;
  var etkili = 0.0;
  var sirali = 0;
  for (var n = 0; n < kodlar.length; n++) {
    final fark = n == 0 ? null : kodlar[n] - kodlar[n - 1];
    if (fark == 0 || fark == 1 || fark == -1) {
      etkili += 0.25;
      sirali++;
    } else {
      etkili += 1;
    }
  }
  if (sirali >= 3 && sirali * 3 >= kodlar.length) {
    uyarilar.add('Tekrarlanan ya da sıralı karakterler (aaa, 123, abc) tahmini kolaylaştırır.');
  }

  for (final dizi in _klavyeDizileri) {
    if (sade.contains(dizi)) {
      etkili -= dizi.length - 1;
      uyarilar.add('Klavyede yan yana duran tuşlar ($dizi) bilinen bir kalıptır.');
      break;
    }
  }

  if (RegExp(r'19[5-9]\d|20[0-4]\d').hasMatch(parola)) {
    etkili -= 2;
    uyarilar.add('Doğum yılı gibi tarihler kolay tahmin edilir.');
  }

  if (kodlar.length < 12) {
    uyarilar.add('En az 12 karakter kullanın; uzunluk, karmaşıklıktan daha çok güç katar.');
  }
  if (rakamVar && !kucukVar && !buyukVar && !simgeVar) {
    uyarilar.add('Yalnızca rakamlardan oluşuyor.');
  } else if ([kucukVar, buyukVar, rakamVar, simgeVar].where((v) => v).length == 1 && kodlar.length < 16) {
    uyarilar.add('Tek tür karakter kullanılmış; harf, rakam ve simgeyi karıştırın ya da parolayı uzatın.');
  }

  final bit = max(etkili, 1.0) * log(havuz) / ln2;
  var duzey = switch (bit) {
    < 28 => ParolaDuzeyi.cokZayif,
    < 40 => ParolaDuzeyi.zayif,
    < 60 => ParolaDuzeyi.orta,
    < 80 => ParolaDuzeyi.guclu,
    _ => ParolaDuzeyi.cokGuclu,
  };
  if (kodlar.length < 8 && duzey.index > ParolaDuzeyi.zayif.index) duzey = ParolaDuzeyi.zayif;
  return ParolaSonucu(duzey, bit, uyarilar);
}

/// Seçilen karakter kümelerinin her birinden en az bir karakter içeren rastgele parola.
String parolaUret({
  int uzunluk = 16,
  bool kucuk = true,
  bool buyuk = true,
  bool rakam = true,
  bool simge = true,
  Random? rastgele,
}) {
  final r = rastgele ?? Random.secure();
  final kumeler = [if (kucuk) _kucuk, if (buyuk) _buyuk, if (rakam) _rakam, if (simge) _simge];
  if (kumeler.isEmpty) kumeler.add(_kucuk);
  final hepsi = kumeler.join();
  final harfler = [
    for (final k in kumeler.take(uzunluk)) k[r.nextInt(k.length)],
    for (var n = kumeler.length; n < uzunluk; n++) hepsi[r.nextInt(hepsi.length)],
  ]..shuffle(r);
  return harfler.join();
}

/// [parolaUret] çıktısının yaklaşık gücü (bit).
double parolaBiti({required int uzunluk, bool kucuk = true, bool buyuk = true, bool rakam = true, bool simge = true}) {
  var havuz = (kucuk ? _kucuk.length : 0) + (buyuk ? _buyuk.length : 0) + (rakam ? _rakam.length : 0) + (simge ? _simge.length : 0);
  if (havuz == 0) havuz = _kucuk.length;
  return uzunluk * log(havuz) / ln2;
}

/// Rastgele seçilmiş kelimelerden oluşan, akılda tutması kolay parola cümlesi.
String parolaCumlesiUret({int kelime = 6, String ayrac = '-', Random? rastgele}) {
  final r = rastgele ?? Random.secure();
  return [for (var n = 0; n < kelime; n++) kelimeListesi[r.nextInt(kelimeListesi.length)]].join(ayrac);
}

/// [parolaCumlesiUret] çıktısının gücü (bit); kelime listesinin boyutundan hesaplanır.
double cumleBiti(int kelime) => kelime * log(kelimeListesi.length) / ln2;

final List<String> kelimeListesi = _kelimeler.trim().split(RegExp(r'\s+')).toSet().toList();

const _kelimeler = '''
aslan kaplan kartal şahin serçe karga leylek martı balina yunus köpek kedi tavşan sincap kirpi kaplumbağa kurbağa
yılan timsah zürafa fil gergedan maymun ayı kurt tilki çakal geyik ceylan deve koyun keçi inek manda horoz tavuk
ördek kaz hindi papağan baykuş bülbül güvercin arı karınca kelebek böcek örümcek akrep balık somon levrek hamsi
ahtapot yengeç midye
dağ tepe ova vadi orman çayır bozkır çöl deniz göl ırmak dere şelale pınar ada kıyı kumsal kaya taş toprak kum
çamur bulut yağmur kar dolu sis rüzgar fırtına şimşek gökkuşağı güneş ay yıldız gezegen bahar yaz güz kış sabah
öğle akşam gece şafak
elma armut ayva erik kiraz vişne şeftali kayısı incir üzüm nar portakal mandalina limon muz çilek karpuz kavun
domates biber patlıcan kabak salatalık soğan sarımsak patates havuç ıspanak marul maydanoz nane kekik fesleğen
ceviz fındık badem fıstık kestane buğday arpa mısır pirinç mercimek nohut fasulye ekmek peynir zeytin bal reçel
çorba pilav börek simit helva lokum çay kahve ayran şerbet
masa sandalye koltuk dolap raf kapı pencere perde halı yastık yorgan lamba mum ayna saat takvim defter kalem silgi
cetvel kitap gazete dergi mektup zarf pul çanta cüzdan anahtar kilit zincir çekiç çivi vida tornavida testere
makas iğne iplik düğme kumaş gömlek ceket kazak atkı eldiven şapka çorap ayakkabı terlik şemsiye gözlük bardak
tabak kaşık çatal bıçak tencere tava çaydanlık sürahi kova süpürge fırça sabun havlu tarak
ev köy kasaba şehir sokak cadde meydan köprü kule kale saray çarşı pazar dükkan fırın okul kütüphane müze sinema
tiyatro stadyum liman iskele istasyon havalimanı araba otobüs tren vapur gemi kayık uçak bisiklet motosiklet
kamyon traktör tekerlek direksiyon yelken kürek pusula harita bavul bilet
mavi yeşil sarı kırmızı turuncu mor pembe beyaz siyah gri kahverengi lacivert büyük küçük uzun kısa geniş dar
hızlı yavaş sıcak soğuk ılık serin tatlı tuzlu ekşi acı yumuşak sert parlak mat sessiz gürültülü neşeli sakin
cesur dikkatli sabırlı çalışkan meraklı nazik
koşu yürüyüş yüzme dans şarkı türkü masal hikaye şiir resim heykel oyun bulmaca satranç tavla top raket ağ çadır
ateş duman kıvılcım gölge ışık ses yankı fısıltı kahkaha gülümseme rüya uyku hayal umut sevinç merak cesaret
sabır emek başarı
demir bakır gümüş altın çelik cam tahta kağıt plastik lastik pamuk yün ipek deri mermer granit kömür tuz şeker un
yağ sirke baharat tarçın karanfil zencefil susam
el kol omuz diz ayak parmak göz kulak burun ağız diş saç kaş anne baba kardeş abla dede nine teyze dayı amca hala
komşu arkadaş misafir çocuk bebek
saz kaval davul zurna keman piyano gitar flüt nota ritim melodi sahne
''';
