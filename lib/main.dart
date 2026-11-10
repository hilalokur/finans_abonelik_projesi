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
          setState(() {
            abonelikler = data['veri'];
            toplamTutar = abonelikler.fold(0.0, (sum, item) => sum + (item['Ucret'] as num).toDouble());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonelik & Finans Yönetimi'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (dovizKurlari.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('USD/TRY: ${dovizKurlari['TRY']?.toStringAsFixed(2) ?? 'N/A'}'),
                            Text('EUR/TRY: ${dovizKurlari['EUR']?.toStringAsFixed(2) ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aktif Aboneliklerim',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 10),
                  abonelikler.isEmpty
                      ? const Center(child: Text('Henüz eklenmiş abonelik yok.'))
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
        onPressed: () {
          verileriGetir();
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}