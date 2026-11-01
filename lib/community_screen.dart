import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedCategory = 'Toutes';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'Toutes',
    'Musculation',
    'HYROX',
    'Fitness',
    'Cardio / Running',
    'Crossfit',
    'Yoga / Etirements',
  ];

  final List<Map<String, dynamic>> _partnerRequests = [
    {
      'id': '1',
      'user_name': 'Syra Champagne',
      'type': 'HYROX',
      'location': 'Gym / Salle proche (5 km)',
      'description': 'Recherche un(e) partenaire pour une session HYROX ce soir ou ce week-end ! Motivation garantie 🥊🔥',
      'date_time': 'Aujourd\'hui - 18h30',
      'status': 'Disponible',
    },
    {
      'id': '2',
      'user_name': 'Marc D.',
      'type': 'Musculation',
      'location': 'Fitness Park (3 km)',
      'description': 'Cherche un spotteur pour séance Pecs / Triceps lourd. Session à 12h.',
      'date_time': 'Demain - 12h00',
      'status': 'Disponible',
    },
    {
      'id': '3',
      'user_name': 'Sophie L.',
      'type': 'Fitness',
      'location': 'Parc municipal (2 km)',
      'description': 'Petite session Fitness & Cardio en plein air. Qui est motivé(e) ?',
      'date_time': 'Samedi - 10h00',
      'status': 'Disponible',
    },
  ];

  void _createNewRequest() {
    final typeController = ValueNotifier<String>('Musculation');
    final descController = TextEditingController();
    final locationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Proposer ou chercher une séance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE05297)),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: typeController,
                builder: (context, currentType, _) {
                  return DropdownButtonFormField<String>(
                    value: currentType,
                    dropdownColor: const Color(0xFF2A2A2A),
                    decoration: InputDecoration(
                      labelText: 'Type de séance',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Musculation', 'HYROX', 'Fitness', 'Cardio / Running', 'Crossfit']
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) typeController.value = val;
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Lieu / Ville / Salle',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Détails de la demande',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE05297),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final user = _supabase.auth.currentUser;
                  final name = user?.userMetadata?['full_name'] ??
                      (user?.email != null ? user!.email!.split('@')[0] : 'Membre SychaFit');

                  if (descController.text.trim().isNotEmpty) {
                    setState(() {
                      _partnerRequests.insert(0, {
                        'id': DateTime.now().toString(),
                        'user_name': name,
                        'type': typeController.value,
                        'location': locationController.text.trim().isEmpty ? 'Aux alentours' : locationController.text.trim(),
                        'description': descController.text.trim(),
                        'date_time': 'Prochainement',
                        'status': 'Disponible',
                      });
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Publier l\'annonce', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _partnerRequests.where((req) {
      final matchesCategory = _selectedCategory == 'Toutes' || req['type'] == _selectedCategory;
      final query = _searchController.text.toLowerCase();
      final matchesSearch = req['description'].toString().toLowerCase().contains(query) ||
          req['type'].toString().toLowerCase().contains(query) ||
          req['location'].toString().toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Partenaires aux Alentours'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une séance, ville ou discipline...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFE05297)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE05297),
                        backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredRequests.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun partenaire trouvé.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final req = filteredRequests[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE05297).withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFE05297),
                                      child: Text(
                                        (req['user_name'] as String)[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            req['user_name'],
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          Text(
                                            '📍 ${req['location']}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE05297).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE05297)),
                                      ),
                                      child: Text(
                                        req['type'],
                                        style: const TextStyle(color: Color(0xFFE05297), fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  req['description'],
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '🕒 ${req['date_time']}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE05297),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Message envoyé à ${req['user_name']} !'),
                                            backgroundColor: const Color(0xFFE05297),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.send, size: 16, color: Colors.white),
                                      label: const Text('Proposer', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE05297),
        onPressed: _createNewRequest,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Chercher un partenaire', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
