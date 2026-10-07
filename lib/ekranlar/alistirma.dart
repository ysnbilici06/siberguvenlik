import 'package:flutter/material.dart';

import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'ortak.dart';

class AlistirmaEkrani extends StatelessWidget {
  const AlistirmaEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Depo.i,
      builder: (context, _) {
        final d = Depo.i;
        return Scaffold(
          appBar: AppBar(title: const Text('Alıştırma')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              _AlistirmaKarti(
                Icons.quiz,
                Renkler.mor,
                'Karışık test',
                'On soru; önce çözmedikleriniz ve yanlış yaptıklarınız gelir.',
                d.dogruSoru,
                d.sorular.length,
                'soru doğru',
                () => git(context, TestEkrani(d.testSorulari(10))),
              ),
              const SizedBox(height: 12),
              _AlistirmaKarti(
                Icons.phishing,
                Renkler.turuncu,
                'Gerçek mi, tuzak mı?',
                'Kurgusal SMS, e-posta, arama ve web adreslerini inceleyin; tuzağı siz bulun.',
                d.dogruSenaryo,
                d.senaryolar.length,
                'örnek doğru',
                () => git(context, SenaryoEkrani(d.siradakiSenaryolar(8))),
              ),
              const SizedBox(height: 16),
              const Uyari(
                'Örneklerdeki kurum, kişi ve adreslerin tümü kurgusaldır. Gerçek hayatta emin olamadığınız iletide en güvenli yol, bağlantıya dokunmadan kurumu kendi bildiğiniz kanaldan aramaktır.',
                renk: Renkler.mavi,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlistirmaKarti extends StatelessWidget {
  const _AlistirmaKarti(this.ikon, this.renk, this.baslik, this.aciklama, this.dogru, this.toplam, this.birim, this.dokun);
  final IconData ikon;
  final Color renk;
  final String baslik;
  final String aciklama;
  final int dogru;
  final int toplam;
  final String birim;
  final VoidCallback dokun;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: dokun,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RenkliIkon(ikon, renk, boyut: 48),
                  const SizedBox(width: 14),
                  Expanded(child: Text(baslik, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  const Icon(Icons.play_circle_fill, size: 32),
                ],
              ),
              const SizedBox(height: 10),
              Text(aciklama, style: const TextStyle(height: 1.35)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: toplam == 0 ? 0 : dogru / toplam, minHeight: 8, color: renk),
              ),
              const SizedBox(height: 6),
              Text('$dogru/$toplam $birim', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Verilen soruları sırayla sorar; her cevaptan sonra açıklamayı gösterir.
class TestEkrani extends StatefulWidget {
  const TestEkrani(this.sorular, {super.key, this.baslik = 'Karışık test'});
  final List<Soru> sorular;
  final String baslik;

  @override
  State<TestEkrani> createState() => _TestEkraniState();
}

class _TestEkraniState extends State<TestEkrani> {
  int _sira = 0;
  int? _secim;
  int _dogru = 0;

  void _sec(int n) {
    if (_secim != null) return;
    final s = widget.sorular[_sira];
    setState(() {
      _secim = n;
      if (n == s.dogru) _dogru++;
    });
    Depo.i.soruCevapla(s.id, n == s.dogru);
  }

  @override
  Widget build(BuildContext context) {
    final toplam = widget.sorular.length;
    return Theme(
      data: vurguTemasi(context, Renkler.mor),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.baslik)),
        body: _sira >= toplam
            ? _Sonuc(_dogru, toplam)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Ilerleme(_sira, toplam),
                  const SizedBox(height: 16),
                  Text(widget.sorular[_sira].soru, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35)),
                  const SizedBox(height: 16),
                  for (final (n, secenek) in widget.sorular[_sira].secenekler.indexed)
                    _Secenek(
                      secenek,
                      // Cevaptan sonra doğru seçenek yeşil, yanlış seçilen kırmızı görünür.
                      renk: _secim == null
                          ? null
                          : (n == widget.sorular[_sira].dogru ? Renkler.yesil : (n == _secim ? Renkler.kirmizi : null)),
                      dokun: _secim == null ? () => _sec(n) : null,
                    ),
                  if (_secim != null) ...[
                    const SizedBox(height: 8),
                    _secim == widget.sorular[_sira].dogru
                        ? Uyari(widget.sorular[_sira].aciklama, renk: Renkler.yesil, ikon: Icons.check_circle_outline, baslik: 'Doğru')
                        : Uyari(widget.sorular[_sira].aciklama, renk: Renkler.kirmizi, ikon: Icons.cancel_outlined, baslik: 'Yanlış'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() {
                        _sira++;
                        _secim = null;
                      }),
                      child: Text(_sira + 1 < toplam ? 'Sonraki soru' : 'Sonucu gör'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _Ilerleme extends StatelessWidget {
  const _Ilerleme(this.sira, this.toplam);
  final int sira;
  final int toplam;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: toplam == 0 ? 0 : sira / toplam, minHeight: 8),
          ),
        ),
        const SizedBox(width: 12),
        Text('${sira + 1}/$toplam', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Secenek extends StatelessWidget {
  const _Secenek(this.metin, {this.renk, this.dokun});
  final String metin;
  final Color? renk;
  final VoidCallback? dokun;

  @override
  Widget build(BuildContext context) {
    final cizgi = renk ?? Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: renk?.withValues(alpha: 0.14) ?? Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: cizgi, width: renk == null ? 1 : 2)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: dokun,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(metin, style: const TextStyle(fontSize: 15, height: 1.3)),
          ),
        ),
      ),
    );
  }
}

class _Sonuc extends StatelessWidget {
  const _Sonuc(this.dogru, this.toplam);
  final int dogru;
  final int toplam;

  @override
  Widget build(BuildContext context) {
    if (toplam == 0) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Gösterilecek soru yok.')));
    }
    final tam = dogru == toplam;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(tam ? Icons.emoji_events : Icons.flag, size: 72, color: tam ? Renkler.turuncu : Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('$dogru / $toplam doğru', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              tam ? 'Hepsini bildiniz.' : 'Yanlış yaptıklarınız bir sonraki denemede öne alınır.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Bitir')),
          ],
        ),
      ),
    );
  }
}

/// "Gerçek mi, tuzak mı?": iletiyi gösterir, kararı alır, sonra dikkat edilecek yerleri işaretler.
class SenaryoEkrani extends StatefulWidget {
  const SenaryoEkrani(this.senaryolar, {super.key});
  final List<Senaryo> senaryolar;

  @override
  State<SenaryoEkrani> createState() => _SenaryoEkraniState();
}

class _SenaryoEkraniState extends State<SenaryoEkrani> {
  int _sira = 0;

  /// Kullanıcının kararı: "tuzak" dediyse true.
  bool? _karar;
  int _dogru = 0;

  void _kararVer(bool tuzak) {
    final s = widget.senaryolar[_sira];
    setState(() {
      _karar = tuzak;
      if (tuzak == s.tuzak) _dogru++;
    });
    Depo.i.senaryoCevapla(s.id, tuzak == s.tuzak);
  }

  @override
  Widget build(BuildContext context) {
    final toplam = widget.senaryolar.length;
    return Theme(
      data: vurguTemasi(context, Renkler.turuncu),
      child: Scaffold(
        appBar: AppBar(title: const Text('Gerçek mi, tuzak mı?')),
        body: _sira >= toplam ? _Sonuc(_dogru, toplam) : _govde(widget.senaryolar[_sira], toplam),
      ),
    );
  }

  Widget _govde(Senaryo s, int toplam) {
    final bildi = _karar == s.tuzak;
    final renk = s.tuzak ? Renkler.kirmizi : Renkler.yesil;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Ilerleme(_sira, toplam),
        const SizedBox(height: 16),
        if (s.durum.isNotEmpty) ...[
          Uyari(s.durum, renk: Renkler.mavi, ikon: Icons.person_outline, baslik: 'Durumunuz'),
          const SizedBox(height: 12),
        ],
        Ileti(s, isaretli: _karar != null),
        const SizedBox(height: 16),
        if (_karar == null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _kararVer(false),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Güvenli'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _kararVer(true),
                  icon: const Icon(Icons.phishing),
                  label: const Text('Tuzak'),
                ),
              ),
            ],
          )
        else ...[
          Uyari(
            s.aciklama,
            renk: bildi ? Renkler.yesil : Renkler.kirmizi,
            ikon: bildi ? Icons.check_circle_outline : Icons.cancel_outlined,
            baslik: '${bildi ? 'Doğru' : 'Yanlış'}: ${s.tuzak ? 'bu bir tuzak' : 'bu ileti güvenli'}',
          ),
          if (s.kisisel) ...[
            const SizedBox(height: 8),
            const Uyari(
              'Bu iletideki adınızı ve şehrinizi uygulamaya siz verdiniz. Dolandırıcılar aynı bilgileri veri sızıntılarından ve sosyal medyadan alır. Bir iletinin sizi tanıması onu ne güvenli ne de tehlikeli yapar; belirleyici olan sizden ne istediğidir.',
              renk: Renkler.mavi,
              ikon: Icons.person_search,
              baslik: 'Bu ileti size özeldi',
            ),
          ],
          if (s.isaretler.isNotEmpty) Bolum(s.tuzak ? 'Ele veren işaretler' : 'Güven veren işaretler'),
          for (final i in s.isaretler)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.parca, style: TextStyle(fontWeight: FontWeight.w800, backgroundColor: renk.withValues(alpha: 0.25))),
                      const SizedBox(height: 4),
                      Text(i.aciklama, style: const TextStyle(height: 1.35)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => setState(() {
              _sira++;
              _karar = null;
            }),
            child: Text(_sira + 1 < toplam ? 'Sonraki örnek' : 'Sonucu gör'),
          ),
        ],
      ],
    );
  }
}

/// Senaryodaki iletiyi türüne göre (SMS, e-posta, arama, web adresi) çizer.
class Ileti extends StatelessWidget {
  const Ileti(this.senaryo, {super.key, this.isaretli = false});
  final Senaryo senaryo;

  /// Açıkken [Senaryo.isaretler]deki parçalar ileti üzerinde renklendirilir.
  final bool isaretli;

  static const _turler = <String, (IconData, String, String)>{
    'sms': (Icons.sms, 'SMS', 'Gönderen'),
    'eposta': (Icons.mail, 'E-posta', 'Kimden'),
    'arama': (Icons.call, 'Telefon araması', 'Arayan'),
    'adres': (Icons.language, 'Web adresi', ''),
  };

  @override
  Widget build(BuildContext context) {
    final s = senaryo;
    final (ikon, ad, gonderenEtiketi) = _turler[s.tur] ?? (Icons.message, 'İleti', 'Gönderen');
    final zemin = (s.tuzak ? Renkler.kirmizi : Renkler.yesil).withValues(alpha: 0.3);
    final parcalar = isaretli ? [for (final i in s.isaretler) i.parca] : const <String>[];
    final renkler = Theme.of(context).colorScheme;

    Widget satir(String etiket, String deger) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$etiket: ', style: TextStyle(color: renkler.onSurfaceVariant)),
            isaretliMetin(deger, parcalar, zemin: zemin),
          ])),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: renkler.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: renkler.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 18, color: renkler.primary),
              const SizedBox(width: 6),
              Text(ad, style: TextStyle(fontWeight: FontWeight.w700, color: renkler.primary)),
            ],
          ),
          const SizedBox(height: 10),
          if (s.gonderen.isNotEmpty) satir(gonderenEtiketi, s.gonderen),
          if (s.baslik.isNotEmpty) satir('Konu', s.baslik),
          if (s.gonderen.isNotEmpty || s.baslik.isNotEmpty) const Divider(height: 16),
          Text.rich(
            isaretliMetin(s.metin, parcalar, zemin: zemin),
            style: TextStyle(fontSize: 15.5, height: 1.45, fontFamily: s.tur == 'adres' ? 'monospace' : null),
          ),
        ],
      ),
    );
  }
}
