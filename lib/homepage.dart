import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'login_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    AddDataPage(),
    ExploreTab(),
    OrderListPage(),
  ];
  final FirebaseAuth _auth = FirebaseAuth.instance;
 Future<void> _logout() async {
    await _auth.signOut();
    // Navigasi ke halaman login setelah logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TripIndo'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Tambah Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Detail',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Data Belanja User',
          ),
        ],
      ),
    );
  }
}

class AddDataPage extends StatefulWidget {
  const AddDataPage({Key? key}) : super(key: key);

  @override
  _AddDataPageState createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  final TextEditingController _namaLokasiController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  XFile? _selectedImage;
  String? _currentAddress;
  Position? _currentPosition;

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final XFile? image = await imagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _tambahData() async {
    if (_selectedImage != null && _currentPosition != null) {
      final fileName = _selectedImage!.name;
      final destination = 'lokasi_images/$fileName';
      final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
      final uploadTask = ref.putFile(
        File(_selectedImage!.path),
        firebase_storage.SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('lokasi').add({
        'nama_lokasi': _namaLokasiController.text,
        'harga': _hargaController.text,
        'alamat': _currentAddress,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'gambar': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data berhasil ditambahkan')),
      );

      _namaLokasiController.clear();
      _hargaController.clear();
      _alamatController.clear();
      setState(() {
        _selectedImage = null;
        _currentAddress = null;
        _currentPosition = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih gambar dan dapatkan lokasi terlebih dahulu')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    PermissionStatus permission = await Permission.locationWhenInUse.request();
    if (permission == PermissionStatus.granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
        });

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        Placemark placemark = placemarks.first;
        String address =
            '${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}';
        setState(() {
          _alamatController.text = address;
          _currentAddress = address;
        });
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Izin akses lokasi ditolak')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _namaLokasiController,
              decoration: InputDecoration(labelText: 'Nama Lokasi'),
            ),
            TextField(
              controller: _hargaController,
              decoration: InputDecoration(labelText: 'Harga'),
            ),
            TextField(
              controller: _alamatController,
              decoration: InputDecoration(labelText: 'Alamat'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: Text('Dapatkan Lokasi'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pilih Gambar'),
            ),
            SizedBox(height: 16.0),
            _selectedImage != null
                ? Image.file(File(_selectedImage!.path))
                : Placeholder(fallbackHeight: 200),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _tambahData,
              child: Text('Tambah Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExploreTab extends StatefulWidget {
  @override
  _ExploreTabState createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  late Stream<QuerySnapshot> _stream;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance.collection('lokasi').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> _deleteItem(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('lokasi').doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Item deleted successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete item'),
      ));
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by location name',contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(60.0),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _search,
                icon: Icon(Icons.search),
              ),
              IconButton(
                onPressed: _clearSearch,
                icon: Icon(Icons.clear),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              final data = snapshot.data!.docs;

              List<QueryDocumentSnapshot> filteredData = [];
              if (_searchQuery.isNotEmpty) {
                filteredData = data
                    .where((doc) => doc['nama_lokasi']
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();
              } else {
                filteredData = data;
              }

              return ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final item =
                      filteredData[index].data() as Map<String, dynamic>;

                  final imageUrl = item['gambar'] as String?;
                  final namaLokasi = item['nama_lokasi'] as String?;
                  final harga = item['harga'] as String?;
                  final alamat = item['alamat'] as String?;
                  final documentId = filteredData[index].id;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            documentId: documentId,
                            imageUrl: imageUrl,
                            namaLokasi: namaLokasi,
                            harga: harga,
                            alamat: alamat,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2.0,
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8.0),
                                    topRight: Radius.circular(8.0),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    width: 500,
                                    height: 300,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namaLokasi ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Rp ${harga ?? ''}',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 3),
                                Text(alamat ?? ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
}



class OrderListPage extends StatefulWidget {
  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late Stream<QuerySnapshot> _ordersStream;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersStream = FirebaseFirestore.instance.collection('orders').snapshots();
  }


  Future<String> _getUserName(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userSnapshot['name'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Terjadi kesalahan: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada pesanan'));
          }

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map<Widget>((doc) {
              final orderId = doc.id;
              final namaLokasi = doc['namaLokasi'] as String?;
              final harga = doc['harga'] as String?;
              final alamat = doc['alamat'] as String?;
              final userId = doc['userId'] as String?;
              final imageUrl = doc['gambar'] as String?;

              return FutureBuilder<String>(
                future: _getUserName(userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(); // Placeholder widget while waiting for the user name
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final userName = snapshot.data ?? '';

                  return Card(
                    child: ListTile(
                      leading: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                          : Container(),
                      title: Text(namaLokasi ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4,),
                          Text('Nama Pembeli: $userName'), // Display user name
                          SizedBox(height: 4,),
                          Text('Harga: $harga'),
                          SizedBox(height: 4,),
                          Text('Alamat: $alamat'),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}







class DetailPage extends StatefulWidget {
  final String? imageUrl;
  final String? namaLokasi;
  final String? harga;
  final String? alamat;
  final String? documentId;

  const DetailPage({
    Key? key,
    this.imageUrl,
    this.namaLokasi,
    this.harga,
    this.alamat,
    this.documentId,
  }) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}



class _DetailPageState extends State<DetailPage> {
  late TextEditingController _namaLokasiController;
  late TextEditingController _hargaController;
  late TextEditingController _alamatController;
  LatLng? _markerPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _namaLokasiController = TextEditingController(text: widget.namaLokasi);
    _hargaController = TextEditingController(text: widget.harga);
    _alamatController = TextEditingController(text: widget.alamat);
    _updateMarkerPosition(widget.alamat!);
  }

  @override
  void dispose() {
    _namaLokasiController.dispose();
    _hargaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  void _updateMarkerPosition(String address) async {
    LatLng? latLng = await _getLatLngFromAddress(address);
    if (latLng != null) {
      setState(() {
        _markerPosition = latLng;
      });
      _moveCameraToPosition(latLng);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat menemukan lokasi')),
      );
    }
  }

  void _moveCameraToPosition(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  void updateData() async {
    final updatedNamaLokasi = _namaLokasiController.text;
    final updatedHarga = _hargaController.text;
    final updatedAlamat = _alamatController.text;
    final documentId = widget.documentId;

    final docRef = FirebaseFirestore.instance.collection('lokasi').doc(documentId);
    await docRef.update({
      'nama_lokasi': updatedNamaLokasi,
      'harga': updatedHarga,
      'alamat': updatedAlamat,
    });

    _updateMarkerPosition(updatedAlamat); // Perbarui posisi marker berdasarkan alamat baru

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data berhasil diupdate')),
    );
  }

  void navigateToFullscreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMapPage(
          markerPosition: _markerPosition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Center(
            child:
            ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: widget.imageUrl != null ? Image.network(widget.imageUrl!,
            width: 500,
            height: 300,
            fit: BoxFit.cover,) : Container(),
           ),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _namaLokasiController,
            decoration: InputDecoration(labelText: 'Nama Lokasi'),
          ),
          TextField(
            controller: _hargaController,
            decoration: InputDecoration(labelText: 'Harga'),
          ),
          TextField(
            controller: _alamatController,
            decoration: InputDecoration(labelText: 'Alamat'),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: updateData,
            child: Text('Simpan'),
          ),
          SizedBox(height: 16.0),
          Container(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _markerPosition ?? LatLng(0, 0),
                zoom: 15,
              ),
              markers: _markerPosition != null
                  ? {
                      Marker(
                        markerId: MarkerId('location'),
                        position: _markerPosition!,
                      ),
                    }
                  : {},
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: (_) {
                navigateToFullscreenMap();
              },
            ),
          ),
        ],
      ),
    );
  }
}



class MapsPage extends StatefulWidget {
  const MapsPage({Key? key}) : super(key: key);

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(-6.1754, 106.8272); // Koordinat Jakarta

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12.0,
        ),
      ),
    );
  }
}


class FullScreenMapPage extends StatelessWidget {
  final LatLng? markerPosition;

  const FullScreenMapPage({Key? key, this.markerPosition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FullScreen Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: markerPosition ?? LatLng(0, 0),
          zoom: 15,
        ),
        markers: markerPosition != null
            ? {
                Marker(
                  markerId: MarkerId('location'),
                  position: markerPosition!,
                ),
              }
            : {},
      ),
    );
  }
}


