import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const NotesyApp());
}

class NotesyApp extends StatelessWidget {
  const NotesyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notesy',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFCF5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF4C6D5)),
      ),
      home: const NotesyHomePage(),
    );
  }
}

class NotesyHomePage extends StatelessWidget {
  const NotesyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Keeps the title responsive on different devices.
    final titleSize = (screenWidth * 0.11).clamp(38.0, 52.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFFCF5),
        centerTitle: true,

        // Floral decoration + Notesy title
        title: SizedBox(
          height: 85,
          width: screenWidth * 0.65,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Your pink lily graphic
              Positioned(
                left: 0,
                top: 5,
                child: Opacity(
                  opacity: 0.25,
                  child: Icon(
                    Icons.local_florist_rounded,
                    size: 30,
                    color: const Color(0xFFF4C6D5),
                  ),
                ),
              ),

              // Notesy title
              Text(
                'Notesy',
                style: GoogleFonts.slacksideOne(
                  fontSize: titleSize,
                  color: const Color(0xFF66515A),
                ),
              ),
            ],
          ),
        ),

        // Information button
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF806572),
            ),
            onPressed: () {
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
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
          child: Column(
            children: [
              SizedBox(height: screenWidth * 0.10),

              // Main heading
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

              // Cute Create Note card
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Create Note screen coming next! 💗'),
                    ),
                  );
                },
                child: Container(
                  width: (screenWidth * 0.34).clamp(125.0, 160.0),
                  height: (screenWidth * 0.34).clamp(125.0, 160.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3EC),
                    border: Border.all(
                      color: const Color(0xFFB85C7A),
                      width: 2.5,
                    ),
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
                      Icon(
                        Icons.add_rounded,
                        size: 28,
                        color: Color(0xFF806572),
                      ),
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

              // Tiny lemon accent
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
          ),
        ),
      ),
    );
  }
}
