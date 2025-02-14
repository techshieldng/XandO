import 'dart:async';
import 'dart:math' as f;

import 'package:TicTacToe/models/create_game_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FindGame {
  FirebaseDatabase _ins = FirebaseDatabase.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new game
  String createGames(int entryFee, int round, String matrixSize) {
    var game = _ins.ref().child("Game").push();
    var key = game.key;
    var random = f.Random();
    var randomInt = random.nextInt(2);
    var player = randomInt == 0 ? "player1" : "player2";

    var create = CreateGame(
        player1: _auth.currentUser!.uid.toString(),
        entryFee: entryFee,
        round: round,
        tryy: player,
        matrixSize: matrixSize);

    game.set(create.toMap());

    return key!;
  }

  // Join an existing game or create a new one
  Future<Map<String, dynamic>> joinGame(
      entryFee, round, String matrixSize) async {
    JoinStatus joinGameStatus = JoinStatus.pending;
    String roomKey = "";
    String? oppornentKey = "";

    DatabaseEvent dta = await _ins.ref().child("Game").once();

    // If there are no games available, create a new one
    if (dta.snapshot.value == null) {
      roomKey = await createGames(entryFee, round, matrixSize);

      joinGameStatus = JoinStatus.created;
    } else {
      Map<dynamic, dynamic> valMap = dta.snapshot.value as Map;

      for (int i = 0; i < valMap.length; i++) {
        var status = valMap.values.elementAt(i)["status"];
        var player1 = valMap.values.elementAt(i)["player1"]["id"];
        var _entryFee = valMap.values.elementAt(i)["entryFee"];
        var _round = valMap.values.elementAt(i)["round"];
        var _matrixSize = valMap.values.elementAt(i)["matrixSize"];

        // Check if the matrix sizes are the same
        if (player1 != _auth.currentUser!.uid &&
            status == "pending" &&
            _entryFee == entryFee &&
            _round == round &&
            _matrixSize == matrixSize) {
          roomKey = valMap.keys.elementAt(i);
          oppornentKey = player1;
          joinGameStatus = JoinStatus.joined;
          break;
        }
      }

      // If no available game is found, create a new game
      if (joinGameStatus != JoinStatus.joined) {
        roomKey = await createGames(entryFee, round, matrixSize);
        joinGameStatus = JoinStatus.created;
      } else {
        // Update game status and player information
        await _ins.ref().child("Game").child(roomKey).update({
          "status": "preparing",
        });
        await _ins.ref().child("Game").child(roomKey).child("player2").update({
          "id": _auth.currentUser!.uid,
          "won": 0,
        });
      }
    }

    Map<String, dynamic> map = {
      "JoinStatus": joinGameStatus,
      "roomKey": roomKey,
      "oppornentKey": oppornentKey,
    };

    return map;
  }

  // Calculate time difference
  int timeDifferance(String time) {
    DateTime gameCreatedDate = DateTime.parse(time);
    DateTime nowDate = DateTime.now().toUtc();

    int differance = gameCreatedDate.difference(nowDate).inMinutes;
    return differance;
  }
}

enum JoinStatus {
  created,
  joined,
  pending,
  error,
}
