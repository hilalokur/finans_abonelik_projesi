import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const FinansAbonelikApp());
}

class FinansAbonelikApp extends StatelessWidget {
  const FinansAbonelikApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finans Abonelik Takip',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  AnaSayfa({Key? key}) : super(key: key);

  @override
  _AnaSayfaState createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List abonelikler = [];
  bool yukleniyor = true;
  double toplamTutar = 0.0;
  Map<String, dynamic> dovizKurlari = {};
  Map<String, double> kategoriDagilimi = {};

  @override
  void initState() {
    super.initState();
    verileriGetir();
    dovizKurlariniGetir();
  }

  Future<void> verileriGetir() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/abonelikleri-getir'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['durum'] == 'Başarılı') {
          List gelenListe = data['veri'];
          double toplam = 0.0;
          Map<String, double> dagilim = {};

          for (var item in gelenListe) {
            double ucret = (item['Ucret'] as num).toDouble();
            String kategori = item['Kategori'] ?? 'Diğer';
            toplam += ucret;

            if (dagilim.containsKey(kategori)) {
              dagilim[kategori] = dagilim[kategori]! + ucret;
            } else {
              dagilim[kategori] = ucret;
            }
          }

          setState(() {
            abonelikler = gelenListe;
            toplamTutar = toplam;
            kategoriDagilimi = dagilim;
            yukleniyor = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        yukleniyor = false;
      });
      print("Bağlantı hatası: $e");
    }
  }

  Future<void> dovizKurlariniGetir() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/doviz-kurlari'));
      if (response.statusCode == 200) {
        setState(() {
          dovizKurlari = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Döviz çekme hatası: $e");
    }
  }

  void yeniAbonelikSayfasiniAc() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => YeniAbonelikSayfasi(onEklendi: verileriGetir)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonelik & Finans Yönetimi'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: yeniAbonelikSayfasiniAc,
            tooltip: 'Yeni Abonelik Ekle',
          ),
        ],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Özet Kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.indigo, Colors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Toplam Aylık Abonelik Gideri',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${toplamTutar.toStringAsFixed(2)} TL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Döviz Kurları Özeti
                  if (dovizKurlari.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('USD/TRY: ${dovizKurlari['TRY']?.toStringAsFixed(2) ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('EUR/TRY: ${dovizKurlari['EUR']?.toStringAsFixed(2) ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Kategori Bazlı Harcama İstatistik Kartları (Grafiksel Görünüm)
                  const Text(
                    'Kategori Bazlı Harcama Dağılımı',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 10),
                  kategoriDagilimi.isEmpty
                      ? const Text('Henüz harcama verisi yok.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: kategoriDagilimi.keys.length,
                          itemBuilder: (context, index) {
                            String kategori = kategoriDagilimi.keys.elementAt(index);
                            double tutar = kategoriDagilimi[kategori]!;
                            double yuzde = toplamTutar > 0 ? (tutar / toplamTutar) : 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('${tutar.toStringAsFixed(2)} TL (${(yuzde * 100).toStringAsFixed(1)}%)',
                                            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: yuzde,
                                      backgroundColor: Colors.grey[200],
                                      color: Colors.indigo,
                                      minHeight: 8,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),

                  const Text(
                    'Aktif Aboneliklerim',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 10),

                  // Abonelik Listesi
                  abonelikler.isEmpty
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(30.0),
                          child: Text('Henüz eklenmiş abonelik yok. Sağ üstteki + butonundan ekleyebilirsin!'),
                        ))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: abonelikler.length,
                          itemBuilder: (context, index) {
                            var item = abonelikler[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.withOpacity(0.1),
                                  child: const Icon(Icons.subscriptions, color: Colors.indigo),
                                ),
                                title: Text(item['AbonelikAdi'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Kategori: ${item['Kategori']} • ${item['YenilemePeriyodu']}'),
                                trailing: Text(
                                  '${item['Ucret']} ${item['ParaBirimi']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: yeniAbonelikSayfasiniAc,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class YeniAbonelikSayfasi extends StatefulWidget {
  final VoidCallback onEklendi;
  YeniAbonelikSayfasi({Key? key, required this.onEklendi}) : super(key: key);

  @override
  _YeniAbonelikSayfasiState createState() => _YeniAbonelikSayfasiState();
}

class _YeniAbonelikSayfasiState extends State<YeniAbonelikSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _ucretController = TextEditingController();
  String _kategori = 'Eğlence';
  String _paraBirimi = 'TL';
  String _periyod = 'Aylık';

  bool _yukleniyor = false;

  Future<void> abonelikEkle() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _yukleniyor = true; });
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/abonelik-ekle'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "AbonelikAdi": _adController.text,
            "Kategori": _kategori,
            "Ucret": double.parse(_ucretController.text),
            "ParaBirimi": _paraBirimi,
            "YenilemePeriyodu": _periyod,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          widget.onEklendi();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Abonelik eklenirken bir hata oluştu!')),
          );
        }
      } catch (e) {
        print("Hata: $e");
      } finally {
        setState(() { _yukleniyor = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Abonelik Ekle'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _adController,
                decoration: const InputDecoration(labelText: 'Abonelik Adı (örn: Netflix, Spotify)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Lütfen bir ad girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ucretController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ücret', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Lütfen bir ücret girin' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _kategori,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: <String>['Eğlence', 'Yazılım', 'Bulut', 'Fatura', 'Diğer']
                    .map((String label) => DropdownMenuItem<String>(value: label, child: Text(label)))
                    .toList(),
                onChanged: (String? val) { setState(() { _kategori = val!; }); },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paraBirimi,
                decoration: const InputDecoration(labelText: 'Para Birimi', border: OutlineInputBorder()),
                items: <String>['TL', 'USD', 'EUR']
                    .map((String label) => DropdownMenuItem<String>(value: label, child: Text(label)))
                    .toList(),
                onChanged: (String? val) { setState(() { _paraBirimi = val!; }); },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _periyod,
                decoration: const InputDecoration(labelText: 'Yenileme Periyodu', border: OutlineInputBorder()),
                items: <String>['Aylık', 'Yıllık']
                    .map((String label) => DropdownMenuItem<String>(value: label, child: Text(label)))
                    .toList(),
                onChanged: (String? val) { setState(() { _periyod = val!; }); },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  onPressed: _yukleniyor ? null : abonelikEkle,
                  child: _yukleniyor
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Aboneliği Kaydet', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}