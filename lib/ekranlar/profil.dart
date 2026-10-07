import 'package:flutter/material.dart';

import '../veri/depo.dart';
import '../veri/profil.dart';
import 'ortak.dart';

/// Ad, yaş aralığı ve şehir alanları. Hepsi isteğe bağlıdır; boş bırakılan alan kaydedilmez.
class ProfilFormu extends StatefulWidget {
  const ProfilFormu({super.key, required this.bitti, this.atlanabilir = false});

  /// Kaydedildikten ya da atlandıktan sonra çağrılır.
  final VoidCallback bitti;

  /// Karşılama ekranında "Atla" düğmesini gösterir.
  final bool atlanabilir;

  @override
  State<ProfilFormu> createState() => _ProfilFormuState();
}

class _ProfilFormuState extends State<ProfilFormu> {
  late final _ad = TextEditingController(text: Depo.i.ad);
  String? _yas = Depo.i.yas;
  String? _sehir = Depo.i.sehir;

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    await Depo.i.profilKaydet(ad: _ad.text, yas: _yas, sehir: _sehir);
    widget.bitti();
  }

  Future<void> _atla() async {
    await Depo.i.karsilamayiGec();
    widget.bitti();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Uyari(
          'Bu bilgiler yalnızca bu cihazda saklanır, hiçbir yere gönderilmez ve istediğiniz an silinebilir. Hepsi isteğe bağlıdır.',
          renk: Renkler.yesil,
          ikon: Icons.lock_outline,
        ),
        const SizedBox(height: 12),
        const Text(
          'Verirseniz alıştırmalardaki örnek iletiler, gerçek dolandırıcıların yaptığı gibi adınızı ve şehrinizi kullanır; yaş aralığınıza göre de konu öneririz.',
          style: TextStyle(height: 1.4),
        ),
        const Bolum('Adınız'),
        TextField(
          controller: _ad,
          maxLength: adSiniri,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Yalnızca adınız; soyad gerekmez', counterText: ''),
        ),
        const Bolum('Yaş aralığınız'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in yasGruplari.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _yas == e.key,
                onSelected: (secili) => setState(() => _yas = secili ? e.key : null),
              ),
          ],
        ),
        const Bolum('Şehriniz'),
        DropdownButtonFormField<String?>(
          initialValue: _sehir,
          isExpanded: true,
          hint: const Text('Yaşadığınız il ya da memleketiniz'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Belirtmek istemiyorum')),
            for (final il in iller) DropdownMenuItem<String?>(value: il, child: Text(il)),
          ],
          onChanged: (v) => setState(() => _sehir = v),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _kaydet, child: const Text('Kaydet')),
        if (widget.atlanabilir) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: _atla, child: const Text('Atla')),
        ],
      ],
    );
  }
}

/// İlk açılışta bir kez gösterilen, atlanabilir karşılama ekranı.
class Karsilama extends StatelessWidget {
  const Karsilama({super.key, required this.bitti});
  final VoidCallback bitti;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SayfaBasligi(Icons.shield, Color(0xFF00695C), 'Hoş geldiniz', 'Başlamadan önce örnekleri size göre uyarlayabiliriz.'),
            ProfilFormu(bitti: bitti, atlanabilir: true),
          ],
        ),
      ),
    );
  }
}

/// Ana sayfadan açılan, bilgilerin değiştirildiği ya da silindiği ekran.
class ProfilEkrani extends StatelessWidget {
  const ProfilEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bilgilerim')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfilFormu(
            bitti: () {
              bildir(context, 'Bilgileriniz kaydedildi');
              Navigator.of(context).pop();
            },
          ),
          if (Depo.i.profilVar) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await Depo.i.profilSil();
                if (!context.mounted) return;
                bildir(context, 'Bilgileriniz silindi');
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Bilgilerimi sil'),
              style: TextButton.styleFrom(foregroundColor: Renkler.kirmizi),
            ),
          ],
        ],
      ),
    );
  }
}
