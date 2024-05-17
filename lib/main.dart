import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'event_model.dart';
import 'calendar.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Future<EventModel> model = createEventModel();

  runApp(FutureBuilder(future: model, builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return ChangeNotifierProvider.value(
        value: snapshot.data,
        child: MainApp(),
      );
    } else {
      return MaterialApp(
        title: "RemindMe",
        home: CircularProgressIndicator()
      );
    }
  },));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "RemindMe",
      home: Calendar()
    );
  }
}

