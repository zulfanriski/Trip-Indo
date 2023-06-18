import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'main.dart';


class HomePageUser extends StatefulWidget {
  const HomePageUser({Key? key}) : super(key: key);

  @override
  _HomePageUserState createState() => _HomePageUserState();
}

class _HomePageUserState extends State<HomePageUser> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _logout() async {
    await _auth.signOut();
    // Navigasi ke halaman login setelah logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UserLoginPage()),
    );
  }

  final List<Widget> _pages = [
    ExploreTab(),
    OrderListPage(),
    ProfilePage(),
  ];

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
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    }
  }

  void _deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pesanan berhasil dihapus')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan. Gagal menghapus pesanan')),
      );
    }
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
            children: snapshot.data!.docs.map((doc) {
              final orderId = doc.id;
              final namaLokasi = doc['namaLokasi'] as String?;
              final harga = doc['harga'] as String?;
              final alamat = doc['alamat'] as String?;
              final imageUrl = doc['gambar'] as String?;

              return Card(
                child: ListTile(
                  leading: imageUrl != null ? Image.network(imageUrl, height: 100,
                  width: 100,
                  fit: BoxFit.cover,) : Container(),
                  title: Text(namaLokasi ?? ''),
                  subtitle: Text('Harga: $harga\nAlamat: $alamat'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteOrder(orderId),
                  ),
                ),
              );
            }).toList(),
          );
        },
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
                    hintText: 'Search by location name',contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10) ,
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


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  ImageProvider? _profileImageProvider;
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _addressController.text = userData['address'] ?? '';

          final imageUrl = userData['profileImageUrl'];
          if (imageUrl != null && imageUrl.isNotEmpty) {
            _profileImageProvider = NetworkImage(imageUrl);
          }
        }
        
      );
      }
    }
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userId = user.uid;

      // Get the current profile image URL
      final userData = await _firestore.collection('users').doc(userId).get();
      final currentImageUrl = userData['profileImageUrl'];

      // Upload a new profile image if available
      String? imageUrl;
      if (_image != null) {
        final imageName = userId + DateTime.now().toString();
        final storageReference = FirebaseStorage.instance.ref().child('profile_images/$imageName');
        final uploadTask = storageReference.putFile(_image!);
        await uploadTask.whenComplete(() async {
          imageUrl = await storageReference.getDownloadURL();
        });
      } else {
        // If no new image is selected, preserve the current image URL
        imageUrl = currentImageUrl;
      }

      // Update user data in Firestore
      await _firestore.collection('users').doc(userId).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'profileImageUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.getImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Container(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: Icon(Icons.camera),
                              title: Text('Camera'),
                              onTap: () {
                                _pickImage(ImageSource.camera);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.image),
                              title: Text('Gallery'),
                              onTap: () {
                                _pickImage(ImageSource.gallery);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: CircleAvatar(
                radius: 80.0,
                backgroundImage: _image != null ? FileImage(_image!) : _profileImageProvider,
              ),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              readOnly: true,
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Save'),
            ),
          ],
        ),
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

  void _saveOrder(String documentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final orderData = {
          'userId': user.uid,
          'lokasiId': documentId,
          'timestamp': Timestamp.now(),
          'namaLokasi': widget.namaLokasi,
          'harga': widget.harga,
          'alamat': widget.alamat,
          'gambar' : widget.imageUrl
        };

        await FirebaseFirestore.instance.collection('orders').add(orderData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesanan berhasil disimpan')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda harus login untuk melakukan pembelian')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan. Pesanan gagal disimpan')),
      );
    }
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
          Text(
            widget.namaLokasi ?? '',
            style: TextStyle(fontSize: 16.0),
          ),
          Text(
            widget.harga ?? '',
            style: TextStyle(fontSize: 16.0),
          ),
          Text(
            widget.alamat ?? '',
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () => _saveOrder(widget.documentId!),
            child: Text('Beli'),
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


