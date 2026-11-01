import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_workout_screen.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';

class WorkoutsListScreen extends StatefulWidget {
  const WorkoutsListScreen({super.key});

  @override
  State<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends State<WorkoutsListScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _workouts = [];
  Set<String> _joinedWorkoutIds = {};
  Map<String, int> _participantCounts = {};
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isTimerRunning = false;

  String _selectedCategory = 'Toutes';
  final List<String> _categories = [
    'Toutes',
    'Fessiers & Galbe',
    'Cuisses & Legs',
    'HYROX & Cardio',
    'Upper Body',
    'Abs & Core',
  ];

  final List<Map<String, dynamic>> _presetWorkouts = [
    {
      'title': 'Booty Sculpt & Lift',
      'category': 'Fessiers & Galbe',
      'duration': '45 min',
      'level': 'Intermédiaire',
      'exercises': [
        'Hip Thrust : 4 x 12 (Pause 1s en haut)',
        'Fentes Bulgares : 3 x 10 / jambe',
        'Soulevé de terre jambes tendues : 4 x 12',
        'Cable Kickbacks : 3 x 15 / côté',
      ],
    },
    {
      'title': 'Legday Explosif',
      'category': 'Cuisses & Legs',
      'duration': '50 min',
      'level': 'Avancé',
      'exercises': [
        'Squat barre guidée / libre : 4 x 10',
        'Presse à cuisses : 4 x 12 (Lourd)',
        'Leg Extension : 3 x 15 (Dropset)',
        'Leg Curl allongé : 4 x 12',
      ],
    },
    {
      'title': 'HYROX Circuit Brûle-Graisse',
      'category': 'HYROX & Cardio',
      'duration': '40 min',
      'level': 'Intense',
      'exercises': [
        'SkiErg / Rameur : 500m',
        'Sled Push / Course : 50m',
        'Burpees Broad Jumps : 20 reps',
        'Wall Balls : 25 reps (6kg/9kg)',
      ],
    },
    {
      'title': 'Sculpt Upper Body & Posture',
      'category': 'Upper Body',
      'duration': '35 min',
      'level': 'Tous niveaux',
      'exercises': [
        'Tirage poitrine poulie haute : 4 x 12',
        'Développé militaire haltères : 3 x 12',
        'Elevations latérales : 4 x 15',
        'Dips assistés / Pompe : 3 x Max',
      ],
    },
    {
      'title': 'Ventre Plat & Gainage Intense',
      'category': 'Abs & Core',
      'duration': '20 min',
      'level': 'Tous niveaux',
      'exercises': [
        'Gainage dynamique : 4 x 45 sec',
        'Crunch poulie haute : 4 x 20',
        'Russian Twists avec poids : 3 x 30 sec',
        'Relevé de jambes suspendu : 3 x 12',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchWorkouts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        setState(() => _isTimerRunning = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Temps de repos terminé ! À vous de jouer !'),
              backgroundColor: Color(0xFFE05297),
            ),
          );
        }
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resetTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
      _isTimerRunning = false;
    });
  }

  Future<void> _fetchWorkouts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final response = await _supabase
          .from('workouts')
          .select('id, title, location, description, date_time, user_id')
          .order('date_time', ascending: false);

      final List<Map<String, dynamic>> fetchedWorkouts = List<Map<String, dynamic>>.from(response);

      Set<String> joinedIds = {};
      Map<String, int> counts = {};

      try {
        final participantsResponse = await _supabase.from('workout_participants').select('workout_id, user_id');
        final List participantsList = participantsResponse as List;

        for (var p in participantsList) {
          final workoutId = p['workout_id'] as String;
          final pUserId = p['user_id'] as String;
          counts[workoutId] = (counts[workoutId] ?? 0) + 1;
          if (pUserId == userId) joinedIds.add(workoutId);
        }
      } catch (_) {}

      setState(() {
        _workouts = fetchedWorkouts;
        _joinedWorkoutIds = joinedIds;
        _participantCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleParticipation(String workoutId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final isJoined = _joinedWorkoutIds.contains(workoutId);

    try {
      if (isJoined) {
        await _supabase.from('workout_participants').delete().eq('workout_id', workoutId).eq('user_id', userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous avez quitté la séance')));
        }
      } else {
        await _supabase.from('workout_participants').insert({'workout_id': workoutId, 'user_id': userId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez rejoint la séance !'),
              backgroundColor: Color(0xFFE05297),
            ),
          );
        }
      }
      _fetchWorkouts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  void _showWorkoutDetails(Map<String, dynamic> workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    workout['title'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE05297)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                )
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(workout['level']), backgroundColor: const Color(0xFFE05297).withValues(alpha: 0.2)),
                const SizedBox(width: 8),
                Chip(label: Text(workout['duration']), backgroundColor: Colors.white10),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Exercices de la séance :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            ...(workout['exercises'] as List<String>).map((ex) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFFE05297), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ex, style: const TextStyle(color: Colors.white70))),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE05297),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _resetTimer(60);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Séance démarrée ! Le timer est prêt.')),
                  );
                },
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Démarrer cette séance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutsListView() {
    final filteredPresets = _selectedCategory == 'Toutes'
        ? _presetWorkouts
        : _presetWorkouts.where((p) => p['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('SychaFit - Espace Entraînement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE05297),
          labelColor: const Color(0xFFE05297),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Programmes SychaFit'),
            Tab(icon: Icon(Icons.groups), text: 'Séances Membres'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFE05297)),
            onPressed: _fetchWorkouts,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
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
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE05297).withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFE05297).withValues(alpha: 0.2), blurRadius: 10)
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Color(0xFFE05297), size: 30),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TIMER RÉCUPÉRATION', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
                        Text(
                          '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(_isTimerRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: const Color(0xFFE05297), size: 36),
                      onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                    ),
                    PopupMenuButton<int>(
                      icon: const Icon(Icons.tune, color: Colors.white70),
                      color: const Color(0xFF2A2A2A),
                      onSelected: (sec) => _resetTimer(sec),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 30, child: Text('30 sec')),
                        PopupMenuItem(value: 60, child: Text('60 sec')),
                        PopupMenuItem(value: 90, child: Text('90 sec')),
                        PopupMenuItem(value: 120, child: Text('120 sec')),
                      ],
                    )
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 42,
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
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredPresets.length,
                            itemBuilder: (context, index) {
                              final p = filteredPresets[index];
                              return Card(
                                color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: const Color(0xFFE05297).withValues(alpha: 0.4)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFE05297).withValues(alpha: 0.2),
                                    child: const Icon(Icons.fitness_center, color: Color(0xFFE05297)),
                                  ),
                                  title: Text(p['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  subtitle: Text('${p['duration']} • ${p['level']}', style: const TextStyle(color: Colors.white70)),
                                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFE05297)),
                                  onTap: () => _showWorkoutDetails(p),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE05297)))
                        : _workouts.isEmpty
                            ? const Center(child: Text('Aucune séance partagée.', style: TextStyle(color: Colors.white70)))
                            : ListView.builder(
                                itemCount: _workouts.length,
                                itemBuilder: (context, index) {
                                  final workout = _workouts[index];
                                  final workoutId = workout['id'].toString();
                                  final isJoined = _joinedWorkoutIds.contains(workoutId);
                                  final participantCount = _participantCounts[workoutId] ?? 0;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE05297).withValues(alpha: 0.4)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(workout['title'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                        const SizedBox(height: 4),
                                        Text('📍 ${workout['location'] ?? "Non spécifié"}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Text(workout['description'] ?? '', style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('$participantCount participant(s)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isJoined ? Colors.green.withValues(alpha: 0.3) : const Color(0xFFE05297),
                                              ),
                                              onPressed: () => _toggleParticipation(workoutId),
                                              child: Text(isJoined ? 'Inscrit(e)' : 'Rejoindre', style: const TextStyle(color: Colors.white)),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE05297),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateWorkoutScreen()),
          );
          _fetchWorkouts();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildWorkoutsListView(),
          const CommunityScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFFE05297),
        unselectedItemColor: Colors.white54,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Séances'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Communauté'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
