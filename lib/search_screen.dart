import 'package:flutter/material.dart';
import 'package:smartconnect/local_database.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchTerm = '';
  List<DocumentSnapshot> _results = [];
  bool _isLoading = false;

  Future<void> _performSearch() async {
    if (_searchTerm.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final snapshot = await LocalDatabase.instance
          .collection('vouchers')
          .where('network', isEqualTo: _searchTerm.trim())
          .where('status', isEqualTo: 'available')
          .get();

      setState(() {
        _results = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Imeshindikana kutafuta: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Available Vouchers'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Andika jina la mtandao (mfano: Vodacom)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
              ),
              onChanged: (value) {
                _searchTerm = value.trim();
              },
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(child: Text('🔍 Hakuna vocha zilizopatikana'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final doc = _results[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.sim_card,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Code: ${doc['code']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.network_cell,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Network: ${doc['network']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_offer,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Package: ${doc['package']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
