import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'screens/note_editor_screen.dart';
import 'services/note_storage_service.dart';
import 'screens/planner_screen.dart';

final ValueNotifier<ThemeMode> notesyThemeMode = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedTheme = await NoteStorageService.getThemeMode();

  switch (savedTheme) {
    case 'light':
      notesyThemeMode.value = ThemeMode.light;
      break;
    case 'dark':
      notesyThemeMode.value = ThemeMode.dark;
      break;
    default:
      notesyThemeMode.value = ThemeMode.system;
  }

  runApp(const NotesyApp());
}

class NotesyApp extends StatelessWidget {
  const NotesyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: notesyThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Notesy',

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],

          themeMode: mode,

          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFFFCF5),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFF4C6D5),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFFFCF5),
              foregroundColor: Color(0xFF66515A),
              elevation: 0,
            ),
            drawerTheme: const DrawerThemeData(
              backgroundColor: Color(0xFFFFFCF5),
            ),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF1F1A1D),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD98EA8),
              brightness: Brightness.dark,
              surface: const Color(0xFF292226),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF292226),
              foregroundColor: Color(0xFFFFE8EF),
              elevation: 0,
            ),
            drawerTheme: const DrawerThemeData(
              backgroundColor: Color(0xFF292226),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF292226),
            ),
            useMaterial3: true,
          ),

          home: const NotesyHomePage(),
        );
      },
    );
  }
}

// ============================================================
// HOME
// ============================================================

class NotesyHomePage extends StatefulWidget {
  const NotesyHomePage({super.key});

  @override
  State<NotesyHomePage> createState() => _NotesyHomePageState();
}

class _NotesyHomePageState extends State<NotesyHomePage> {
  List<NotesyNote> _notes = [];

  int _selectedDrawerIndex = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await NoteStorageService.getNotes();

      if (!mounted) return;

      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _notes = [];
        _isLoading = false;
      });
    }
  }

  // ==========================================================
  // CREATE NOTE
  // ==========================================================

  Future<void> _openNewNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
    );

    await _loadNotes();
  }

  // ==========================================================
  // EDIT NOTE
  // ==========================================================

  Future<void> _openExistingNote(NotesyNote note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );

    await _loadNotes();
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> _deleteNote(NotesyNote note) async {
    await NoteStorageService.deleteNote(note.id);

    await _loadNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${note.title}" deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // FAVORITE
  // ==========================================================

  Future<void> _toggleFavorite(NotesyNote note) async {
    final newValue = !note.favorite;

    await NoteStorageService.updateFavorite(note.id, newValue);

    await _loadNotes();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isWide = screenWidth >= 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      drawer: _buildDrawer(context),

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,

        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Menu',
              icon: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF806572),
                size: 27,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        title: SizedBox(
          height: 70,
          width: isWide ? 300 : screenWidth * 0.55,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                top: 12,
                child: Opacity(
                  opacity: 0.25,
                  child: Icon(
                    Icons.local_florist_rounded,
                    size: 30,
                    color: const Color(0xFFF4C6D5),
                  ),
                ),
              ),

              Text(
                'Notesy',
                style: GoogleFonts.slacksideOne(
                  fontSize: (screenWidth * 0.10).clamp(36.0, 50.0),
                  color: const Color(0xFF66515A),
                ),
              ),
            ],
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesyProfileScreen()),
              );
            },
            icon: const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFFFE3EC),
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: Color(0xFF806572),
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: _buildCurrentPage(),

      // ALWAYS AVAILABLE.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFDCE8),
        foregroundColor: const Color(0xFF806572),
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Note',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
        onPressed: _openNewNote,
      ),
    );
  }

  // ==========================================================
  // CURRENT PAGE
  // ==========================================================

  Widget _buildCurrentPage() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB85C7A)),
      );
    }

    switch (_selectedDrawerIndex) {
      case 1:
        return _buildNotesSection(
          title: 'All Notes',
          icon: Icons.notes_rounded,
          notes: _notes,
        );

      case 2:
        return _buildNotesSection(
          title: 'Favorites',
          icon: Icons.favorite_rounded,
          notes: _notes.where((note) => note.favorite).toList(),
        );

      case 3:
        return const WeeklyPlannerScreen();

      default:
        return _buildHomePage();
    }
  }

  // ==========================================================
  // HOME PAGE
  // ==========================================================

  Widget _buildHomePage() {
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (screenWidth * 0.07).clamp(20.0, 60.0),
        ),
        child: Column(
          children: [
            const SizedBox(height: 25),

            Expanded(
              child: _notes.isEmpty ? _buildEmptyHome() : _buildNotesList(),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY HOME
  // ==========================================================

  Widget _buildEmptyHome() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        const SizedBox(height: 25),

        Text(
          "Let's create your first note!",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: (screenWidth * 0.065).clamp(22.0, 30.0),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F4A54),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Your notes will appear here.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: (screenWidth * 0.038).clamp(14.0, 17.0),
            color: const Color(0xFF9A858E),
          ),
        ),

        const Spacer(),

        GestureDetector(
          onTap: _openNewNote,
          child: Container(
            width: (screenWidth * 0.34).clamp(125.0, 160.0),
            height: (screenWidth * 0.34).clamp(125.0, 160.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE3EC),
              border: Border.all(color: const Color(0xFFB85C7A), width: 2.5),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDFAEBD).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🧸', style: TextStyle(fontSize: 48)),
                SizedBox(height: 3),
                Icon(Icons.add_rounded, size: 28, color: Color(0xFF806572)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        Text(
          'Create a new note',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF806572),
          ),
        ),

        const Spacer(),

        Container(
          width: 55,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFF5E7A8),
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(height: 25),
      ],
    );
  }

  // ==========================================================
  // NOTES LIST
  // ==========================================================

  Widget _buildNotesList() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final note = _notes[index];

        return _buildNoteCard(note);
      },
    );
  }

  // ==========================================================
  // NOTE CARD
  // ==========================================================

  Widget _buildNoteCard(NotesyNote note) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openExistingNote(note),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF0D7DF), width: 1.3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDFAEBD).withValues(alpha: 0.12),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3EC),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Color(0xFFB85C7A),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isEmpty ? 'Untitled Note' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5F4A54),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      note.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFF9A858E),
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      note.dateLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFFB29CA5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  IconButton(
                    tooltip: note.favorite ? 'Remove favorite' : 'Add favorite',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _toggleFavorite(note),
                    icon: Icon(
                      note.favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: note.favorite
                          ? const Color(0xFFB85C7A)
                          : const Color(0xFFB9A4AC),
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF9A858E),
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteNote(note);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFF806572),
                            ),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ALL NOTES / FAVORITES
  // ==========================================================

  Widget _buildNotesSection({
    required String title,
    required IconData icon,
    required List<NotesyNote> notes,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          (screenWidth * 0.07).clamp(20.0, 60.0),
          25,
          (screenWidth * 0.07).clamp(20.0, 60.0),
          90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3EC),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: const Color(0xFFB85C7A)),
                ),

                const SizedBox(width: 12),

                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5F4A54),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Text(
                        title == 'Favorites'
                            ? 'No favorite notes yet.'
                            : 'No notes yet.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: const Color(0xFF9A858E),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: notes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildNoteCard(notes[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DRAWER
  // ==========================================================

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE3EC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFFB85C7A),
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    'Notesy',
                    style: GoogleFonts.slacksideOne(
                      fontSize: 30,
                      color: const Color(0xFF66515A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _drawerItem(icon: Icons.home_rounded, title: 'Home', index: 0),

            _drawerItem(
              icon: Icons.notes_rounded,
              title: 'All Notes',
              index: 1,
            ),

            _drawerItem(
              icon: Icons.favorite_rounded,
              title: 'Favorites',
              index: 2,
            ),

            _drawerItem(
              icon: Icons.calendar_month_rounded,
              title: 'Weekly Planner',
              index: 3,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Divider(color: Color(0xFFF0DDE3)),
            ),

            ListTile(
              leading: const Icon(
                Icons.person_rounded,
                color: Color(0xFF806572),
              ),
              title: Text(
                'Profile',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF66515A),
                ),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotesyProfileScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.settings_rounded,
                color: Color(0xFF806572),
              ),
              title: Text(
                'Settings',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF66515A),
                ),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotesySettingsScreen(),
                  ),
                );
              },
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Notesy • 1.0.0',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: const Color(0xFFB29CA5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final selected = _selectedDrawerIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFFFFE8EF),
        leading: Icon(
          icon,
          color: selected ? const Color(0xFFB85C7A) : const Color(0xFF806572),
        ),
        title: Text(
          title,
          style: GoogleFonts.nunito(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF66515A),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onTap: () {
          setState(() {
            _selectedDrawerIndex = index;
          });

          Navigator.pop(context);
        },
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class NotesyProfileScreen extends StatefulWidget {
  const NotesyProfileScreen({super.key});

  @override
  State<NotesyProfileScreen> createState() => _NotesyProfileScreenState();
}

class _NotesyProfileScreenState extends State<NotesyProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _loadingProfile = true;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await NoteStorageService.getProfileName();
    final username = await NoteStorageService.getProfileUsername();

    if (!mounted) return;

    _nameController.text = name.isEmpty ? 'Notesy User' : name;
    _usernameController.text = username.isEmpty ? '@notesy_user' : username;

    setState(() {
      _loadingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_savingProfile) return;

    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both name and username.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _savingProfile = true;
    });

    await NoteStorageService.saveProfile(name: name, username: username);

    if (!mounted) return;

    setState(() {
      _savingProfile = false;
    });

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF66515A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 25, 24, 35),
          child: Column(
            children: [
              const SizedBox(height: 10),

              const CircleAvatar(
                radius: 58,
                backgroundColor: Color(0xFFFFE3EC),
                child: Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: Color(0xFFB85C7A),
                ),
              ),

              const SizedBox(height: 25),

              _profileField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 15),

              _profileField(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.alternate_email_rounded,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDCE8),
                    foregroundColor: const Color(0xFF806572),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _loadingProfile || _savingProfile
                      ? null
                      : _saveProfile,
                  child: _savingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save Profile',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.nunito(
        color: const Color(0xFF66515A),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(color: const Color(0xFF9A858E)),
        prefixIcon: Icon(icon, color: const Color(0xFFB85C7A)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFF0D7DF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFF0D7DF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB85C7A), width: 1.5),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class NotesySettingsScreen extends StatefulWidget {
  const NotesySettingsScreen({super.key});

  @override
  State<NotesySettingsScreen> createState() => _NotesySettingsScreenState();
}

class _NotesySettingsScreenState extends State<NotesySettingsScreen> {
  ThemeMode get _themeMode => notesyThemeMode.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF66515A),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            Text(
              'Appearance',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF66515A),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF0D7DF)),
              ),
              child: RadioGroup<ThemeMode>(
                groupValue: _themeMode,
                onChanged: (value) {
                  if (value == null) return;

                  notesyThemeMode.value = value;
                  setState(() {
                    // Rebuild this screen with the updated theme selection.
                  });

                  NoteStorageService.saveThemeMode(
                    value == ThemeMode.light
                        ? 'light'
                        : value == ThemeMode.dark
                        ? 'dark'
                        : 'system',
                  );
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      activeColor: const Color(0xFFB85C7A),
                      title: Text(
                        'Light',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF66515A),
                        ),
                      ),
                      secondary: const Icon(
                        Icons.light_mode_rounded,
                        color: Color(0xFF806572),
                      ),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      activeColor: const Color(0xFFB85C7A),
                      title: Text(
                        'Dark',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF66515A),
                        ),
                      ),
                      secondary: const Icon(
                        Icons.dark_mode_rounded,
                        color: Color(0xFF806572),
                      ),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      activeColor: const Color(0xFFB85C7A),
                      title: Text(
                        'System default',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF66515A),
                        ),
                      ),
                      secondary: const Icon(
                        Icons.settings_brightness_rounded,
                        color: Color(0xFF806572),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'About',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF66515A),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF0D7DF)),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF806572),
                ),
                title: Text(
                  'About Notesy',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF66515A),
                  ),
                ),
                subtitle: Text(
                  'Version 1.0.0',
                  style: GoogleFonts.nunito(color: const Color(0xFF9A858E)),
                ),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Notesy',
                    applicationVersion: '1.0.0',
                    children: const [
                      Text(
                        'A cute and simple place to create and organize your notes.',
                      ),
                    ],
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
