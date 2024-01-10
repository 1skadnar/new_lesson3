
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('calculationBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController inputController1 = TextEditingController();
  final TextEditingController inputController2 = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<int> calculationHistory = [];
  List<String> allChanges = [];

  Future<void> _saveResult(int result) async {
    final calculationBox = await Hive.openBox('calculationBox');
    await calculationBox.put('lastResult', result);
  }

  Future<int?> _loadLastResult() async {
    final calculationBox = await Hive.openBox('calculationBox');
    return calculationBox.get('lastResult');
  }

  void _performOperation(int Function(int, int) operation, String operationName) async {
    final userInput1 = inputController1.text;
    final userInput2 = inputController2.text;
    final number1 = int.tryParse(userInput1) ?? 0;
    final number2 = int.tryParse(userInput2) ?? 0;
    final result = operation(number1, number2);

    await _saveResult(result);

    setState(() {
      calculationHistory.add(result);
      allChanges.add('Performed $operationName operation');
    });

    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text('Result: $result'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(color: Colors.blue),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () {
            ScaffoldMessenger.of(_scaffoldKey.currentContext!).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget buildActionButtons(TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildActionButton(controller, Icons.add, () {
          _performOperation((a, b) => a + b, 'addition');
        }),
        buildActionButton(controller, Icons.remove, () {
          _performOperation((a, b) => a - b, 'subtraction');
        }),
        buildActionButton(controller, Icons.close, () {
          _performOperation((a, b) => a * b, 'multiplication');
        }),
      ],
    );
  }

  Widget buildActionButton(
      TextEditingController controller, IconData icon, Function() onPressed) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Calculator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: inputController1,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'First number',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TextField(
                  controller: inputController2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Second number',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              buildActionButtons(inputController2),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showHistory();
                  _printAllChanges();
                },
                child: const Text('Save'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final lastResult = await _loadLastResult();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryPage(
                        allChanges: allChanges,
                        lastResult: lastResult,
                      ),
                    ),
                  );
                },
                child: const Text(' History '),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory() async {
    final calculationBox = await Hive.openBox('calculationBox');

    int? lastResult = await _loadLastResult();
    List<int> calculationHistory = [...this.calculationHistory];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Calculation History'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                if (lastResult != null) Text('Last Result: $lastResult'),
                ...calculationHistory.map((result) => Text('Result: $result')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveResult(lastResult!);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printAllChanges() async {
    print('All Changes:');

    final calculationBox = await Hive.openBox('calculationBox');
    int? lastResult = await _loadLastResult();

    if (lastResult != null) {
      print('- Last Result: $lastResult');
    }

    for (String change in allChanges) {
      print('- $change');
    }
  }
}

class HistoryPage extends StatelessWidget {
  final List<String> allChanges;
  final int? lastResult;

  const HistoryPage({
    Key? key,
    required this.allChanges,
    required this.lastResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Page'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (lastResult != null) Text('Last Result: $lastResult'),
              const SizedBox(height: 20),
              for (String change in allChanges) Text(change),
            ],
          ),
        ),
      ),
    );
  }
}
