import 'package:flutter/material.dart';

import '../veri/depo.dart';
import '../veri/modeller.dart';
import '../veri/parola.dart';
import 'ortak.dart';

/// Her aracın simgesi, vurgu rengi ve kısa açıklaması; sayfa başlığıyla anahtarlanır.
const aracGorunumu = <String, (IconData, Color, String)>{
  'Parola Gücü': (Icons.password, Renkler.turkuaz, 'Parolanızın ne kadar dayanıklı olduğuna bakın.'),
  'Parola Üretici': (Icons.casino, Renkler.mor, 'Rastgele parola ya da akılda kalan parola cümlesi üretin.'),
  'Kontrol Listeleri': (Icons.checklist, Renkler.yesil, 'Hesap ve cihazlarınızı adım adım güvene alın.'),
  'Mağdur Oldum': (Icons.support, Renkler.kirmizi, 'Hesabınız çalındıysa ya da dolandırıldıysanız ne yapmalısınız?'),
};

class AraclarEkrani extends StatelessWidget {
  const AraclarEkrani({super.key});

  static const _sayfalar = <String, Widget>{
    'Parola Gücü': ParolaGucu(),
    'Parola Üretici': ParolaUretici(),
    'Kontrol Listeleri': KontrolListeleri(),
    'Mağdur Oldum': MagdurRehberi(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Araçlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          for (final e in _sayfalar.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: RenkliIkon(aracGorunumu[e.key]!.$1, aracGorunumu[e.key]!.$2),
                  title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(aracGorunumu[e.key]!.$3),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => git(context, e.value),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Araç sayfalarının ortak iskeleti: başlık şeridi ve aracın vurgu rengiyle boyanmış tema.
class AracSayfasi extends StatelessWidget {
  const AracSayfasi(this.baslik, {super.key, required this.cocuklar});
  final String baslik;
  final List<Widget> cocuklar;

  @override
  Widget build(BuildContext context) {
    final (ikon, renk, aciklama) = aracGorunumu[baslik]!;
    return Theme(
      data: vurguTemasi(context, renk),
      child: Scaffold(
        appBar: AppBar(title: Text(baslik)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [SayfaBasligi(ikon, renk, baslik, aciklama), ...cocuklar],
        ),
      ),
    );
  }
}

Color _duzeyRengi(ParolaDuzeyi d) => switch (d) {
      ParolaDuzeyi.cokZayif => Renkler.kirmizi,
      ParolaDuzeyi.zayif => Renkler.turuncu,
      ParolaDuzeyi.orta => Renkler.kahve,
      ParolaDuzeyi.guclu => Renkler.yesil,
      ParolaDuzeyi.cokGuclu => Renkler.turkuaz,
    };

class ParolaGucu extends StatefulWidget {
  const ParolaGucu({super.key});

  @override
  State<ParolaGucu> createState() => _ParolaGucuState();
}

class _ParolaGucuState extends State<ParolaGucu> {
  // Parola yalnızca bu sayfa açıkken bellekte durur; hiçbir yere yazılmaz.
  final _alan = TextEditingController();
  bool _gizli = true;

  @override
  void dispose() {
    _alan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sonuc = parolaDegerlendir(_alan.text);
    final renk = _duzeyRengi(sonuc.duzey);
    return AracSayfasi('Parola Gücü', cocuklar: [
      const Uyari(
        'Yazdığınız parola kaydedilmez ve cihazınızdan çıkmaz; hesap tümüyle bu cihazda yapılır.',
        renk: Renkler.yesil,
        ikon: Icons.lock_outline,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _alan,
        obscureText: _gizli,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Parola',
          suffixIcon: IconButton(
            tooltip: _gizli ? 'Göster' : 'Gizle',
            icon: Icon(_gizli ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _gizli = !_gizli),
          ),
        ),
      ),
      if (_alan.text.isNotEmpty) ...[
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sonuc.duzey.ad, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: renk)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: (sonuc.duzey.index + 1) / ParolaDuzeyi.values.length, minHeight: 10, color: renk),
                ),
                const SizedBox(height: 12),
                if (sonuc.uyarilar.isEmpty)
                  const Text('Belirgin bir zayıflık görülmedi.')
                else
                  for (final u in sonuc.uyarilar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: Renkler.turuncu),
                          const SizedBox(width: 8),
                          Expanded(child: Text(u, style: const TextStyle(height: 1.35))),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      const Uyari(
        'Bu bir tahmindir. Güçlü bir parola bile başka bir sitede de kullanılıyorsa ya da bir dolandırıcıya söylenirse korumaz: her hesaba ayrı parola ve iki adımlı doğrulama kullanın.',
        renk: Renkler.mavi,
      ),
    ]);
  }
}

class ParolaUretici extends StatefulWidget {
  const ParolaUretici({super.key});

  @override
  State<ParolaUretici> createState() => _ParolaUreticiState();
}

class _ParolaUreticiState extends State<ParolaUretici> {
  bool _cumle = false;
  int _uzunluk = 16;
  int _kelime = 6;
  bool _buyuk = true;
  bool _rakam = true;
  bool _simge = true;
  late String _sonuc = _uret();

  String _uret() => _cumle
      ? parolaCumlesiUret(kelime: _kelime)
      : parolaUret(uzunluk: _uzunluk, buyuk: _buyuk, rakam: _rakam, simge: _simge);

  void _degistir(VoidCallback ayar) => setState(() {
        ayar();
        _sonuc = _uret();
      });

  @override
  Widget build(BuildContext context) {
    final bit = _cumle ? cumleBiti(_kelime) : parolaBiti(uzunluk: _uzunluk, buyuk: _buyuk, rakam: _rakam, simge: _simge);
    return AracSayfasi('Parola Üretici', cocuklar: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Rastgele parola'), icon: Icon(Icons.shuffle)),
          ButtonSegment(value: true, label: Text('Parola cümlesi'), icon: Icon(Icons.short_text)),
        ],
        selected: {_cumle},
        onSelectionChanged: (s) => _degistir(() => _cumle = s.first),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(_sonuc, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'monospace', height: 1.4)),
              const SizedBox(height: 8),
              Text('Yaklaşık güç: ${bit.round()} bit', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(onPressed: () => _degistir(() {}), icon: const Icon(Icons.refresh), label: const Text('Yenile')),
                  OutlinedButton.icon(onPressed: () => kopyala(context, _sonuc), icon: const Icon(Icons.copy), label: const Text('Kopyala')),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (_cumle) ...[
        Text('Kelime sayısı: $_kelime'),
        Slider(value: _kelime.toDouble(), min: 4, max: 10, divisions: 6, label: '$_kelime', onChanged: (v) => _degistir(() => _kelime = v.round())),
        Uyari(
          'Kelimeler ${kelimeListesi.length} kelimelik bir listeden rastgele seçilir. Daha çok kelime, daha güçlü cümle demektir.',
          renk: Renkler.mavi,
        ),
      ] else ...[
        Text('Uzunluk: $_uzunluk'),
        Slider(value: _uzunluk.toDouble(), min: 8, max: 40, divisions: 32, label: '$_uzunluk', onChanged: (v) => _degistir(() => _uzunluk = v.round())),
        SwitchListTile(value: _buyuk, onChanged: (v) => _degistir(() => _buyuk = v), title: const Text('Büyük harf'), contentPadding: EdgeInsets.zero),
        SwitchListTile(value: _rakam, onChanged: (v) => _degistir(() => _rakam = v), title: const Text('Rakam'), contentPadding: EdgeInsets.zero),
        SwitchListTile(value: _simge, onChanged: (v) => _degistir(() => _simge = v), title: const Text('Simge'), contentPadding: EdgeInsets.zero),
      ],
      const SizedBox(height: 12),
      const Uyari(
        'Üretilen parola kaydedilmez. Kopyaladıktan sonra bir parola yöneticisine kaydedin; panoda uzun süre bırakmayın.',
        renk: Renkler.yesil,
        ikon: Icons.lock_outline,
      ),
    ]);
  }
}

class KontrolListeleri extends StatelessWidget {
  const KontrolListeleri({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Depo.i,
      builder: (context, _) => AracSayfasi('Kontrol Listeleri', cocuklar: [
        for (final l in Depo.i.listeler)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: RenkliIkon(ikonCoz(l.ikon), renkCoz(l.renk)),
                title: Text(l.baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: l.maddeler.isEmpty ? 0 : Depo.i.isaretliSayisi(l) / l.maddeler.length,
                      minHeight: 6,
                      color: renkCoz(l.renk),
                    ),
                  ),
                ),
                trailing: Text('${Depo.i.isaretliSayisi(l)}/${l.maddeler.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => git(context, _ListeDetay(l)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _ListeDetay extends StatelessWidget {
  const _ListeDetay(this.liste);
  final KontrolListesi liste;

  @override
  Widget build(BuildContext context) {
    final renk = renkCoz(liste.renk);
    return Theme(
      data: vurguTemasi(context, renk),
      child: ListenableBuilder(
        listenable: Depo.i,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: Text(liste.baslik)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SayfaBasligi(ikonCoz(liste.ikon), renk, liste.baslik, '${Depo.i.isaretliSayisi(liste)}/${liste.maddeler.length} adım tamamlandı'),
              for (final m in liste.maddeler)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Card(
                    child: CheckboxListTile(
                      value: Depo.i.isaretli(liste.id, m.id),
                      onChanged: (v) => Depo.i.isaretle(liste.id, m.id, v ?? false),
                      title: Text(m.metin, style: const TextStyle(height: 1.35)),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MagdurRehberi extends StatelessWidget {
  const MagdurRehberi({super.key});

  @override
  Widget build(BuildContext context) {
    return AracSayfasi('Mağdur Oldum', cocuklar: [
      const Uyari(
        'Can güvenliğiniz tehlikedeyse ya da suç şu anda sürüyorsa beklemeden 112\'yi arayın.',
        renk: Renkler.kirmizi,
        ikon: Icons.emergency,
      ),
      const Bolum('Ne oldu?'),
      for (final r in Depo.i.rehberler)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: RenkliIkon(ikonCoz(r.ikon), renkCoz(r.renk)),
              title: Text(r.baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(r.ozet),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => git(context, RehberDetay(r)),
            ),
          ),
        ),
    ]);
  }
}

class RehberDetay extends StatelessWidget {
  const RehberDetay(this.rehber, {super.key});
  final Rehber rehber;

  @override
  Widget build(BuildContext context) {
    final renk = renkCoz(rehber.renk);
    final kanallar = [for (final k in rehber.kanallar) ?Depo.i.kanallar[k]];
    return Theme(
      data: vurguTemasi(context, renk),
      child: Scaffold(
        appBar: AppBar(title: Text(rehber.baslik)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SayfaBasligi(ikonCoz(rehber.ikon), renk, rehber.baslik, rehber.ozet),
            for (final (n, adim) in rehber.adimlar.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: renk, child: Text('${n + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 12),
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(adim, style: const TextStyle(fontSize: 15, height: 1.4)))),
                  ],
                ),
              ),
            if (kanallar.isNotEmpty) const Bolum('Resmî başvuru kanalları'),
            for (final k in kanallar)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(k.ad, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${k.deger}\n${k.aciklama}\nKaynak: ${k.kaynak}'),
                    isThreeLine: true,
                    trailing: IconButton(tooltip: 'Kopyala', icon: const Icon(Icons.copy), onPressed: () => kopyala(context, k.deger)),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Uyari(
              'Bu rehber genel bilgilendirme amaçlıdır, hukuki danışmanlık değildir. Başvuru kanallarını kullanmadan önce kurumun resmî sitesinden güncelliğini denetleyin.',
              renk: Renkler.mavi,
            ),
          ],
        ),
      ),
    );
  }
}
