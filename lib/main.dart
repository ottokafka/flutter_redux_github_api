import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  final store = Store<AppState>(appReducer,
      initialState: AppState.initial(), middleware: [thunkMiddleware]);
  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;
  MyApp({this.store});

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
        store: store,
        child: MaterialApp(
            title: 'Flutter Redux with API call',
            routes: {
              ViewJson.id: (context) {
                return ViewJson(onInit: () {
                  StoreProvider.of<AppState>(context).dispatch(getJsonAction);
                });
              },
            },
            home: SaveJson()));
  }
}

// Save Json
class SaveJson extends StatelessWidget {
  static const String id = "SaveJson";
  String name;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // A button thats save name
          FlatButton.icon(
              onPressed: () async {
                fetchPhotos(http.Client());
                Navigator.pushNamed(context, ViewJson.id);
              },
              icon: Icon(Icons.save),
              label: Text("save json")),
        ],
      ),
    );
  }
}

// View Redux JSON
class ViewJson extends StatefulWidget {
  static const String id = "ViewJson";
  final void Function() onInit;
  ViewJson({this.onInit});

  @override
  ViewJsonState createState() => ViewJsonState();
}

class ViewJsonState extends State<ViewJson> {
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(),
            body: Column(
              children: <Widget>[
                Center(child: Text("${state.json[0]["id"]}")),
                Center(child: Text("${state.json[0]["name"]}")),
                Center(child: Text("${state.json[0]["full_name"]}")),
              ],
            ),
          );
        });
  }
}

// App State: View initialize the app state file
class AppState {
  final dynamic name;
  final dynamic json;

  AppState({this.name, this.json});

  factory AppState.initial() {
    return AppState(name: null, json: null);
  }
}

/* Actions */
// Desc: gets data from shared preferences on request
class GetNameAction {
  final dynamic _name;

  dynamic get name => this._name;
  GetNameAction(this._name);
}

class GetJsonAction {
  final dynamic json;

  dynamic get name => this.json;
  GetJsonAction(this.json);
}

ThunkAction<AppState> getNameAction = (Store<AppState> store) async {
  final prefs = await SharedPreferences.getInstance();
  final String name = prefs.getString('name');
  store.dispatch(GetNameAction(name));
};

ThunkAction<AppState> getJsonAction = (Store<AppState> store) async {
  final prefs = await SharedPreferences.getInstance();
  final String json = prefs.getString('json');
  final parsed = jsonDecode(json).cast<Map<String, dynamic>>();
  store.dispatch(GetJsonAction(parsed));
};

// Reducer
AppState appReducer(state, action) {
  return AppState(
      name: userReducer(state.name, action),
      json: jsonReducer(state.json, action));
}

userReducer(user, action) {
  if (action is GetNameAction) {
    return action.name;
  }
}

jsonReducer(json, action) {
  if (action is GetJsonAction) {
    return action.json;
  }
}

// This is the api call
Future<List> fetchPhotos(http.Client client) async {
  final response =
      await client.get('https://api.github.com/users/ottokafka/repos');
  print(response.body);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("json", response.body);
}
