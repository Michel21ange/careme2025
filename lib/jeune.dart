import 'dart:convert';
import 'dart:math';

import 'package:careme2025/meditation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BibleVerset {
  final String reference;
  final String text;

  BibleVerset({required this.reference, required this.text});

  factory BibleVerset.fromJson(Map<String, dynamic> json) {
    return BibleVerset(
      reference: json['reference'],
      text: json['texte'],
    );
  }
}

class Jeune extends StatefulWidget {
  const Jeune({super.key});

  @override
  State<Jeune> createState() => _JeuneState();
}

class _JeuneState extends State<Jeune> {
  int currentPageIndex = 0;

  List<Widget> _widgetOptions = [
    JeuneWidget(),
    MeditationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        height: 50,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.purple,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.self_improvement),
            icon: Icon(Icons.self_improvement),
            label: 'Jeûne',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Meditation',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body:
      _widgetOptions.elementAt(currentPageIndex)
    );
  }
}

class JeuneWidget extends StatefulWidget {
  const JeuneWidget({super.key});

  @override
  State<JeuneWidget> createState() => _JeuneWidgetState();
}

class _JeuneWidgetState extends State<JeuneWidget> {

  Map<String, dynamic>? saintsData;
  String saintDuJour = "Chargement...";
  bool isButtonEnabled = false;
  List<BibleVerset> _verset = [];
  BibleVerset? _dailyVerset;
  bool isValidated = false;
  bool showEmojis = false;
  Map<String, bool> validatedDays = {};

  @override
  void initState() {
    super.initState();
    _loadSaintsData();
    _checkTime();
    _loadVerset();
    _loadValidationStatus();
  }

  void _checkTime() {
    final currentTime = TimeOfDay.now();
    // Si l'heure est 18h ou plus, on active le bouton
    if (currentTime.hour >= 18) {
      setState(() {
        isButtonEnabled = true;
      });
    }
  }

  void _onButtonPressed() {
    // Désactive le bouton après clic
    setState(() {
      isButtonEnabled = false;
    });
  }

  Future<void> _loadSaintsData() async {
    // Lire le fichier JSON
    String jsonString = await rootBundle.loadString('assets/json/saints.json');
    Map<String, dynamic> jsonData = json.decode(jsonString);


    // Récupérer la date actuelle
    DateTime now = DateTime.now();
    String mois = now.month.toString();
    String jour = now.day.toString();

    // Vérifier si la date existe dans le JSON
    if (jsonData.containsKey(mois) && jsonData[mois].containsKey(jour)) {
      setState(() {
        saintDuJour = jsonData[mois][jour].join("\n"); // Liste des saints du jour
      });
    } else {
      setState(() {
        saintDuJour = "Aucun saint trouvé pour aujourd'hui.";
      });
    }
  }

  Future<void> _loadVerset() async {
    String jsonString = await rootBundle.loadString('assets/json/versets.json');

    Map<String, dynamic> jsonData = jsonDecode(jsonString);
    List<dynamic> jsonList = jsonData['versets'];
    _verset = jsonList.map((json) => BibleVerset.fromJson(json)).toList();
    await _setDailyVerset();
  }

  Future<void> _setDailyVerset() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);  // Format: YYYY-MM-DD

    // Vérifier si le verset pour aujourd'hui a déjà été affiché
    final lastDisplayedDate = prefs.getString('last_displayed_date');
    if (lastDisplayedDate != todayKey) {
      // Choisir un verset aléatoire parmi les versets non encore affichés
      List<BibleVerset> availableVerset = List.from(_verset);
      String lastDisplayedVerset = prefs.getString('last_displayed_verset') ?? '';
      availableVerset.removeWhere((verset) => verset.reference == lastDisplayedVerset);

      // Choisir un verset aléatoire
      final randomVerset = availableVerset[Random().nextInt(availableVerset.length)];

      // Sauvegarder le verset affiché et la date
      await prefs.setString('last_displayed_date', todayKey);
      await prefs.setString('last_displayed_verset', randomVerset.reference);

      setState(() {
        _dailyVerset = randomVerset;
      });
    } else {
      // Si le verset pour aujourd'hui a déjà été affiché, simplement le récupérer
      String lastDisplayedVerset = prefs.getString('last_displayed_verset') ?? '';
      setState(() {
        _dailyVerset = _verset.firstWhere((verset) => verset.reference == lastDisplayedVerset);
      });
    }
  }

  Future<void> _loadValidationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);

    final lastValidatedDate = prefs.getString('last_validated_date') ?? '';
    final now = DateTime.now();

    Map<String, bool> tempValidatedDays = {};

    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String key = DateFormat('yyyy-MM-dd').format(date);
      tempValidatedDays[key] = prefs.getBool(key) ?? false;
    }

    setState(() {
      validatedDays = tempValidatedDays;
    });

    if (lastValidatedDate == todayKey) {
      setState(() {
        isButtonEnabled = false; // Désactiver le bouton si déjà validé aujourd'hui
      });
    } else {
      setState(() {
        isButtonEnabled = true; // Réactiver le bouton si on est sur un nouveau jour
      });
    }
  }

  Future<void> _saveValidationState() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('last_validated_date', todayKey);
  }

  Future<void> _validateFasting(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dateKey, true);

    setState(() {
      validatedDays[dateKey] = true;
    });

  }

  @override
  Widget build(BuildContext context){
    DateTime now = DateTime.now();
    List<Map<String, String>> lastFiftyDays = List.generate(
      50,
          (index) {
        DateTime date = now.subtract(Duration(days: index));
        return {
          'day': DateFormat('dd').format(date),
          'month': DateFormat('MMM').format(date),
        };
      },
    );
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Les Saints du jour : \n$saintDuJour",
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: lastFiftyDays.map((date) {
                        String dateKey = "${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: lastFiftyDays.indexOf(date))))}";
                        bool isToday = date == lastFiftyDays.first;
                        bool isValidated = validatedDays[dateKey] ?? false;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isToday ? (isValidated ? Colors.green : Colors.purpleAccent) : (isValidated ? Colors.green : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  date['day']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isToday ? Colors.black : Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  date['month']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isToday ? Colors.black : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Stack(
          children: [
            Positioned(
              bottom: 5,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 267,
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Image à gauche
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/coverJeune.png', // Remplace avec l'image souhaitée
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 20), // Espace entre l'image et le texte
                        // Texte et bouton à droite
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jeune du jour',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              _dailyVerset == null
                                  ? CircularProgressIndicator()
                                  : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _dailyVerset!.reference,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "<< ${_dailyVerset!.text} >>",
                                    style: TextStyle(fontSize: 9),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: isButtonEnabled ? () {
                                  setState(() {
                                    showEmojis = true;
                                  });
                                  Future.delayed(Duration(seconds: 5), () {
                                    setState(() {
                                      showEmojis = false;
                                    });
                                  });
                                  String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
                                  _validateFasting(todayKey);
                                  _saveValidationState();
                                  print("=============================================== ${_validateFasting(todayKey)}");
                                  _onButtonPressed();
                                }
                                    : null,
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      isButtonEnabled ? Colors.purple : Colors.grey),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  )),
                                ),
                                child: Text(
                                  'Valider',
                                  style: TextStyle(
                                    color: isButtonEnabled ? Colors.white : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Affichage des emojis lorsque showEmojis est vrai
            if (showEmojis)
              Positioned.fill(
                child: Stack(
                  children: List.generate(15, (index) {
                    // Positionnement aléatoire des emojis
                    double randomLeft = Random().nextDouble() * MediaQuery.of(context).size.width;
                    double randomTop = Random().nextDouble() * MediaQuery.of(context).size.height;
                    double randomRotation = Random().nextDouble() * 2 * pi; // Rotation aléatoire

                    return AnimatedPositioned(
                      left: randomLeft,
                      top: randomTop,
                      duration: Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      child: Transform.rotate(
                        angle: randomRotation,
                        child: Text(
                          ['🎉', '🥳', '🎊', '🎈', '🎁'][index % 5], // Emoji aléatoire
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

