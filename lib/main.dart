import 'package:flutter/material.dart';

import 'ekranlar/alistirma.dart';
import 'ekranlar/ana_sayfa.dart';
import 'ekranlar/araclar.dart';
import 'ekranlar/ogren.dart';
import 'ekranlar/ortak.dart';
import 'ekranlar/profil.dart';
import 'veri/depo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Depo.i.baslat();
  runApp(const SiberKalkanUygulamasi());
}

class SiberKalkanUygulamasi extends StatelessWidget {
  const SiberKalkanUygulamasi({super.key});

  ThemeData _tema(Brightness parlaklik) {
    final renkler = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00695C),
      brightness: parlaklik,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );
    return ThemeData(
      colorScheme: renkler,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        color: renkler.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: uygulamaAdi,
      debugShowCheckedModeBanner: false,
      theme: _tema(Brightness.light),
      darkTheme: _tema(Brightness.dark),
      home: const _Giris(),
    );
  }
}

/// İlk açılışta karşılama ekranını, sonrasında doğrudan uygulamayı gösterir.
class _Giris extends StatefulWidget {
  const _Giris();

  @override
  State<_Giris> createState() => _GirisState();
}

class _GirisState extends State<_Giris> {
  // Açılıştaki değer tutulur; profil sonradan silinse de karşılama yeniden çıkmaz.
  bool _karsilandi = Depo.i.karsilandi;

  @override
  Widget build(BuildContext context) =>
      _karsilandi ? const Kabuk() : Karsilama(bitti: () => setState(() => _karsilandi = true));
}

/// Alt gezinme çubuğuyla dört ana bölümü barındıran iskelet.
class Kabuk extends StatefulWidget {
  const Kabuk({super.key});

  @override
  State<Kabuk> createState() => _KabukState();
}

class _KabukState extends State<Kabuk> {
  int _sekme = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _sekme,
        children: [
          AnaSayfa(sekmeyeGit: (i) => setState(() => _sekme = i)),
          const OgrenEkrani(),
          const AlistirmaEkrani(),
          const AraclarEkrani(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _sekme,
        onDestinationSelected: (i) => setState(() => _sekme = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Öğren'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz), label: 'Alıştırma'),
          NavigationDestination(icon: Icon(Icons.construction_outlined), selectedIcon: Icon(Icons.construction), label: 'Araçlar'),
        ],
      ),
    );
  }
}
