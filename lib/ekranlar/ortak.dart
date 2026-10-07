import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const uygulamaAdi = 'Siber Kalkan';

Future<T?> git<T>(BuildContext context, Widget ekran) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => ekran));

void bildir(BuildContext context, String mesaj) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mesaj), behavior: SnackBarBehavior.floating));
}

Future<void> kopyala(BuildContext context, String metin) async {
  await Clipboard.setData(ClipboardData(text: metin));
  if (context.mounted) bildir(context, 'Panoya kopyalandı');
}

/// Uygulama genelinde bölümleri ayırt etmek için kullanılan vurgu renkleri.
abstract final class Renkler {
  static const mavi = Color(0xFF1976D2);
  static const lacivert = Color(0xFF283593);
  static const kirmizi = Color(0xFFE53935);
  static const turuncu = Color(0xFFF57C00);
  static const yesil = Color(0xFF2E9E5B);
  static const turkuaz = Color(0xFF0097A7);
  static const mor = Color(0xFF7B3FC4);
  static const kahve = Color(0xFF8D5B3E);
  static const pembe = Color(0xFFD81B60);
}

/// `icerik.json`daki `renk` alanının alabileceği değerler.
const renkler = <String, Color>{
  'mavi': Renkler.mavi,
  'lacivert': Renkler.lacivert,
  'kirmizi': Renkler.kirmizi,
  'turuncu': Renkler.turuncu,
  'yesil': Renkler.yesil,
  'turkuaz': Renkler.turkuaz,
  'mor': Renkler.mor,
  'kahve': Renkler.kahve,
  'pembe': Renkler.pembe,
};

/// `icerik.json`daki `ikon` alanının alabileceği değerler.
const ikonlar = <String, IconData>{
  'olta': Icons.phishing,
  'parola': Icons.password,
  'iki_adim': Icons.verified_user,
  'kisi': Icons.psychology,
  'sosyal': Icons.groups,
  'alisveris': Icons.shopping_cart,
  'wifi': Icons.wifi,
  'telefon': Icons.smartphone,
  'uyari': Icons.warning_amber,
  'cocuk': Icons.child_care,
  'eposta': Icons.mail,
  'banka': Icons.account_balance,
  'hesap': Icons.manage_accounts,
  'para': Icons.payments,
  'kart': Icons.credit_card,
  'santaj': Icons.report,
};

Color renkCoz(String ad) => renkler[ad] ?? Renkler.mavi;
IconData ikonCoz(String ad) => ikonlar[ad] ?? Icons.shield_outlined;

/// Renkli, hafif geçişli zemin üzerinde beyaz simge.
class RenkliIkon extends StatelessWidget {
  const RenkliIkon(this.ikon, this.renk, {super.key, this.boyut = 42});
  final IconData ikon;
  final Color renk;
  final double boyut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boyut,
      height: boyut,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color.lerp(renk, Colors.white, 0.22)!, renk], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(boyut * 0.3),
        boxShadow: [BoxShadow(color: renk.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Icon(ikon, color: Colors.white, size: boyut * 0.55),
    );
  }
}

/// Sayfaların tepesindeki renkli tanıtım şeridi: büyük simge, başlık ve kısa açıklama.
class SayfaBasligi extends StatelessWidget {
  const SayfaBasligi(this.ikon, this.renk, this.baslik, this.aciklama, {super.key});
  final IconData ikon;
  final Color renk;
  final String baslik;
  final String aciklama;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.lerp(renk, Colors.black, 0.28)!, renk, Color.lerp(renk, Colors.white, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: renk.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          // Zemindeki büyük, soluk simge sayfaya kimlik verir.
          Positioned(right: -18, bottom: -26, child: Icon(ikon, size: 130, color: Colors.white.withValues(alpha: 0.14))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(16)),
                  child: Icon(ikon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                      if (aciklama.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(aciklama, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sayfayı kendi vurgu rengine boyar: düğmeler, kaydırıcılar ve giriş alanları bu rengi alır.
ThemeData vurguTemasi(BuildContext context, Color renk) {
  final t = Theme.of(context);
  return t.copyWith(colorScheme: ColorScheme.fromSeed(seedColor: renk, brightness: t.brightness, dynamicSchemeVariant: DynamicSchemeVariant.vibrant));
}

class Bolum extends StatelessWidget {
  const Bolum(this.baslik, {super.key, this.sag});
  final String baslik;
  final Widget? sag;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(child: Text(baslik, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ?sag,
        ],
      ),
    );
  }
}

/// Renkli zemin üzerinde simgeli bilgi ya da uyarı kutusu.
class Uyari extends StatelessWidget {
  const Uyari(this.metin, {super.key, this.renk = Renkler.turuncu, this.ikon = Icons.info_outline, this.baslik});
  final String metin;
  final Color renk;
  final IconData ikon;
  final String? baslik;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: renk, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (baslik != null) Text(baslik!, style: TextStyle(fontWeight: FontWeight.w800, color: renk)),
                Text(metin, style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// [metin]i, [parcalar]ın harfi harfine geçtiği yerler [zemin] rengiyle işaretli olarak verir.
TextSpan isaretliMetin(String metin, Iterable<String> parcalar, {required Color zemin}) {
  final araliklar = <(int, int)>[];
  for (final p in parcalar) {
    if (p.isEmpty) continue;
    for (var n = metin.indexOf(p); n >= 0; n = metin.indexOf(p, n + p.length)) {
      araliklar.add((n, n + p.length));
    }
  }
  araliklar.sort((a, b) => a.$1.compareTo(b.$1));
  final spans = <TextSpan>[];
  var son = 0;
  for (final (bas, bit) in araliklar) {
    if (bit <= son) continue;
    final b = bas < son ? son : bas;
    spans.add(TextSpan(text: metin.substring(son, b)));
    spans.add(TextSpan(text: metin.substring(b, bit), style: TextStyle(backgroundColor: zemin, fontWeight: FontWeight.w800)));
    son = bit;
  }
  spans.add(TextSpan(text: metin.substring(son)));
  return TextSpan(children: spans);
}
