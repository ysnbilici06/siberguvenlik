import 'package:flutter/material.dart';

import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'alistirma.dart';
import 'ortak.dart';

class OgrenEkrani extends StatelessWidget {
  const OgrenEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Depo.i,
      builder: (context, _) {
        final d = Depo.i;
        return Scaffold(
          appBar: AppBar(title: const Text('Öğren')),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: d.konular.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, n) {
              final k = d.konular[n];
              final sorular = d.konuSorulari(k.id);
              final dogru = sorular.where((s) => d.soruSonucu(s.id) == true).length;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: RenkliIkon(ikonCoz(k.ikon), renkCoz(k.renk)),
                  title: Text(k.baslik, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${k.ozet}\nTest: $dogru/${sorular.length} doğru'),
                  isThreeLine: true,
                  trailing: d.okundu(k.id) ? const Icon(Icons.check_circle, color: Renkler.yesil) : const Icon(Icons.chevron_right),
                  onTap: () => git(context, KonuDetay(k)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class KonuDetay extends StatelessWidget {
  const KonuDetay(this.konu, {super.key});
  final Konu konu;

  @override
  Widget build(BuildContext context) {
    final renk = renkCoz(konu.renk);
    return Theme(
      data: vurguTemasi(context, renk),
      child: ListenableBuilder(
        listenable: Depo.i,
        builder: (context, _) {
          final sorular = Depo.i.konuSorulari(konu.id);
          return Scaffold(
            appBar: AppBar(title: Text(konu.baslik)),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SayfaBasligi(ikonCoz(konu.ikon), renk, konu.baslik, konu.ozet),
                for (final p in konu.metin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(p, style: const TextStyle(fontSize: 15.5, height: 1.5)),
                  ),
                if (konu.yap.isNotEmpty) _Maddeler('Yapın', konu.yap, Renkler.yesil, Icons.check_circle_outline),
                if (konu.yapma.isNotEmpty) _Maddeler('Yapmayın', konu.yapma, Renkler.kirmizi, Icons.cancel_outlined),
                const SizedBox(height: 8),
                Card(
                  child: CheckboxListTile(
                    value: Depo.i.okundu(konu.id),
                    onChanged: (v) => Depo.i.okunduYap(konu.id, v ?? false),
                    title: const Text('Bu konuyu okudum'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                if (sorular.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => git(context, TestEkrani(sorular, baslik: '${konu.baslik} testi')),
                    icon: const Icon(Icons.quiz),
                    label: Text('Konu testini çöz (${sorular.length} soru)'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Maddeler extends StatelessWidget {
  const _Maddeler(this.baslik, this.maddeler, this.renk, this.ikon);
  final String baslik;
  final List<String> maddeler;
  final Color renk;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: renk)),
          for (final m in maddeler)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(ikon, size: 20, color: renk),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m, style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
