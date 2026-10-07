import 'package:flutter/material.dart';

import '../veri/depo.dart';
import 'alistirma.dart';
import 'araclar.dart';
import 'ogren.dart';
import 'ortak.dart';
import 'profil.dart';

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key, required this.sekmeyeGit});

  /// Alt gezinme çubuğundaki sekmeye geçer (1 = Öğren).
  final ValueChanged<int> sekmeyeGit;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Depo.i,
      builder: (context, _) {
        final d = Depo.i;
        // İpucu gün içinde değişmez; ertesi gün sıradaki gelir.
        final gun = DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SayfaBasligi(
                  Icons.shield,
                  const Color(0xFF00695C),
                  d.ad.isEmpty ? uygulamaAdi : 'Merhaba ${d.ad}',
                  'Dijital dünyada güvende kalmak için öğrenin, deneyin, denetleyin.',
                ),
                if (d.ipuclari.isNotEmpty) ...[
                  const Bolum('Günün ipucu'),
                  Uyari(d.ipuclari[gun % d.ipuclari.length], renk: Renkler.turuncu, ikon: Icons.lightbulb_outline),
                ],
                const Bolum('İlerlemeniz'),
                Row(
                  children: [
                    Expanded(child: _Ozet('Konu', '${d.okunanKonu}/${d.konular.length}', Renkler.mavi)),
                    const SizedBox(width: 8),
                    Expanded(child: _Ozet('Doğru soru', '${d.dogruSoru}/${d.sorular.length}', Renkler.mor)),
                    const SizedBox(width: 8),
                    Expanded(child: _Ozet('Kontrol', '%${(d.listeOrani * 100).round()}', Renkler.yesil)),
                  ],
                ),
                if (d.onerilenKonular.isNotEmpty) ...[
                  const Bolum('Yaş grubunuza önerilen konular'),
                  for (final k in d.onerilenKonular)
                    _Kisayol(ikonCoz(k.ikon), renkCoz(k.renk), k.baslik, k.ozet, () => git(context, KonuDetay(k))),
                ],
                const Bolum('Hızlı başla'),
                _Kisayol(Icons.menu_book, Renkler.mavi, 'Konuları oku', 'Kısa okumalarla temel bilgileri edinin.', () => sekmeyeGit(1)),
                _Kisayol(Icons.quiz, Renkler.mor, 'Karışık test', 'On soruyla kendinizi deneyin.', () => git(context, TestEkrani(d.testSorulari(10)))),
                _Kisayol(Icons.phishing, Renkler.turuncu, 'Gerçek mi, tuzak mı?', 'Örnek iletilerde tuzağı siz bulun.', () => git(context, SenaryoEkrani(d.siradakiSenaryolar(8)))),
                _Kisayol(Icons.password, Renkler.turkuaz, 'Parola Gücü', 'Parolanızın ne kadar dayanıklı olduğuna bakın.', () => git(context, const ParolaGucu())),
                _Kisayol(Icons.support, Renkler.kirmizi, 'Mağdur Oldum', 'Adım adım ne yapmanız gerektiğini görün.', () => git(context, const MagdurRehberi())),
                const Bolum('Ayarlar'),
                _Kisayol(
                  Icons.person_outline,
                  Renkler.lacivert,
                  'Bilgilerim',
                  d.profilVar ? 'Ad, yaş aralığı ve şehri değiştirin ya da silin.' : 'Örnekleri size göre uyarlamak için ad, yaş aralığı ve şehir ekleyin.',
                  () => git(context, const ProfilEkrani()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Ozet extends StatelessWidget {
  const _Ozet(this.ad, this.deger, this.renk);
  final String ad;
  final String deger;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            FittedBox(child: Text(deger, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: renk))),
            const SizedBox(height: 2),
            Text(ad, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Kisayol extends StatelessWidget {
  const _Kisayol(this.ikon, this.renk, this.baslik, this.aciklama, this.dokun);
  final IconData ikon;
  final Color renk;
  final String baslik;
  final String aciklama;
  final VoidCallback dokun;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: RenkliIkon(ikon, renk),
          title: Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(aciklama),
          trailing: const Icon(Icons.chevron_right),
          onTap: dokun,
        ),
      ),
    );
  }
}
