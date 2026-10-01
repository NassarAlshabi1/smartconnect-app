import 'package:flutter/material.dart';
import 'package:smartconnect/local_backend.dart';
import 'package:shimmer/shimmer.dart';

class BuyVoucherScreen extends StatefulWidget {
  const BuyVoucherScreen({super.key});

  @override
  State<BuyVoucherScreen> createState() => _BuyVoucherScreenState();
}

class _BuyVoucherScreenState extends State<BuyVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedNetwork;
  String? selectedPackage;
  int? selectedPrice;

  List<String> networkOptions = [];
  List<String> assignedPackages = [];

  bool isLoadingNetworks = true;
  bool isLoadingPackages = false;
  bool isLoadingPrice = false;

  @override
  void initState() {
    super.initState();
    _loadNetworkOptions();
  }

  Future<void> _loadNetworkOptions() async {
    try {
      final snapshot = await LocalFirestore.instance.collection('networks').get();
      final networks = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      setState(() {
        networkOptions = networks;
        isLoadingNetworks = false;
      });
    } catch (e) {
      setState(() => isLoadingNetworks = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load networks: $e')),
      );
    }
  }

  Future<void> _loadAssignedPackages(String network) async {
    setState(() {
      isLoadingPackages = true;
      selectedPackage = null;
      selectedPrice = null;
      assignedPackages = [];
    });

    try {
      final snapshot = await LocalFirestore.instance
          .collection('network_packages')
          .where('network', isEqualTo: network)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final packages = List<String>.from(data['packages']);
        setState(() {
          assignedPackages = packages;
        });
      }

      setState(() => isLoadingPackages = false);
    } catch (e) {
      setState(() => isLoadingPackages = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load assigned packages: $e')),
      );
    }
  }

  Future<void> _loadPackagePrice(String packageName) async {
    setState(() {
      isLoadingPrice = true;
      selectedPrice = null;
    });

    try {
      final snapshot = await LocalFirestore.instance
          .collection('voucher_packages')
          .where('name', isEqualTo: packageName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final price = int.parse(snapshot.docs.first['price'].toString());
        setState(() {
          selectedPrice = price;
        });
      }

      setState(() => isLoadingPrice = false);
    } catch (e) {
      setState(() => isLoadingPrice = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load price: $e')),
      );
    }
  }

  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'network': selectedNetwork,
          'package': selectedPackage,
          'price': selectedPrice,
        },
      );
    }
  }

  Widget _buildShimmerDropdown({required String label}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Voucher'),
        backgroundColor: const Color(0xFFFF7043),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              isLoadingNetworks
                  ? _buildShimmerDropdown(label: 'Select Network')
                  : DropdownButtonFormField<String>(
                      value: selectedNetwork,
                      decoration: const InputDecoration(labelText: 'Select Network'),
                      items: networkOptions.map((network) {
                        return DropdownMenuItem(value: network, child: Text(network));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedNetwork = val;
                          selectedPackage = null;
                          selectedPrice = null;
                        });
                        if (val != null) _loadAssignedPackages(val);
                      },
                      validator: (val) => val == null ? 'Please select a network' : null,
                    ),
              const SizedBox(height: 20),
              isLoadingPackages
                  ? _buildShimmerDropdown(label: 'Select Package')
                  : DropdownButtonFormField<String>(
                      value: selectedPackage,
                      decoration: const InputDecoration(labelText: 'Select Package'),
                      items: assignedPackages.map((pkg) {
                        return DropdownMenuItem(value: pkg, child: Text(pkg));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedPackage = val;
                          selectedPrice = null;
                        });
                        if (val != null) _loadPackagePrice(val);
                      },
                      validator: (val) => val == null ? 'Please select a package' : null,
                    ),
              const SizedBox(height: 20),
              if (isLoadingPrice)
                const CircularProgressIndicator()
              else if (selectedPrice != null)
                Text(
                  'Price: TZS $selectedPrice',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}