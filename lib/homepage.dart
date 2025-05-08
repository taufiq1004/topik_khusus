import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<dynamic>> getAllProduct() async {
    String urlAll = "http://10.0.2.2:3000/products";
    try {
      var response = await http.get(Uri.parse(urlAll));
      if (response.statusCode == 200) {
        print("Response Body: ${response.body}"); // Debugging
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal mengambil data: Status ${response.statusCode}");
      }
    } catch (exc) {
      print("Error: $exc"); // Debugging
      throw Exception("Error: $exc");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Bagian atas
            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 0, 191, 255),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 15,
                      right: 15,
                      bottom: 35,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color.fromARGB(255, 0, 191, 255),
                              size: 24,
                            ),
                          ),
                        ),
                        const Text(
                          "Selamat Berbelanja!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart,
                              color: Colors.white, size: 30),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.only(left: 25, right: 25, bottom: 25),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Apa yang anda butuhkan?",
                              hintStyle: const TextStyle(
                                  color: Colors.grey, fontSize: 15),
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.grey, size: 24),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bagian produk dengan FutureBuilder
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 255, 255, 255),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: FutureBuilder<List<dynamic>>(
                    future: getAllProduct(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text("Tidak ada produk tersedia"));
                      }

                      final dataProduct = snapshot.data!;
                      return GridView.builder(
                        itemCount: dataProduct.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                        ),
                        itemBuilder: (context, index) {
                          final itemData = dataProduct[index];
                          return Card(
                            child: Column(
                              children: <Widget>[
                                Image.network(
                                  itemData['image'] ?? '',
                                  width: double.infinity,
                                  height: 100,
                                  fit: BoxFit.fill,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              (loadingProgress.expectedTotalBytes ??
                                                  1)
                                          : null,
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Text(
                                      "Gagal Memuat Gambar Produk",
                                      textAlign: TextAlign.justify,
                                    );
                                  },
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  child: Text(
                                    itemData['name'] ?? 'Nama Tidak Tersedia',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Rp ${itemData['price']?.toString() ?? '0'}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.inventory,
                                            size: 10,
                                            color: Colors.red,
                                          ),
                                          Text(
                                            itemData['stock']?.toString() ?? '0',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}