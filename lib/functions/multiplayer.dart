import 'package:TicTacToe/helpers/constant.dart';
import 'package:TicTacToe/screens/splash.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class Multiplayer {
  final _userRef = FirebaseDatabase.instance.ref().child("users");

  static var _stream;

  static updateLocalList(
      String? gameKey, dynamic dbIns, void Function(dynamic b) update) {
    _stream = dbIns
        .ref()
        .child("Game")
        .child(gameKey)
        .child("buttons")
        .onChildChanged
        .listen((DatabaseEvent ev) {
      update(ev);
    });
  }

  // Method to check status
  static Future<void> checkStatus(
    BuildContext context,
    String gameKey,
    Map<dynamic, dynamic> buttons,
    String matrixSize, // Change parameter type to int
    dynamic gameStatus, {
    void Function(int index)? onWin,
    void Function(int index)? onTie,
  }) async {
    int called = 0;
    String? winner = "0";
    var tieCalled = 0;
    int _count = 0;

    // Choose the winning conditions based on matrix size
    final List<dynamic> currentWinningCondition = (matrixSize == "Four")
        ? utils.winningConditionFour
        : (matrixSize == "Five")
            ? utils.winningConditionFive
            : utils.winningCondition;

// Check for winning conditions
    for (var j = 0; j < currentWinningCondition.length; j++) {
      // Check if the buttons involved in the winning condition are not null
      if (buttons[currentWinningCondition[j][0]] != null &&
          buttons[currentWinningCondition[j][1]] != null &&
          buttons[currentWinningCondition[j][2]] != null &&
          (matrixSize == "Four"
              ? buttons[currentWinningCondition[j][3]] != null
              : (matrixSize == "Five"
                  ? buttons[currentWinningCondition[j][3]] != null &&
                      buttons[currentWinningCondition[j][4]] != null // For 5x5
                  : true)) && // Additional condition for 5x5
          buttons[currentWinningCondition[j][0]]["player"] ==
              buttons[currentWinningCondition[j][1]]["player"] &&
          buttons[currentWinningCondition[j][1]]["player"] ==
              buttons[currentWinningCondition[j][2]]["player"] &&
          (matrixSize == "Four"
              ? buttons[currentWinningCondition[j][2]]["player"] ==
                  buttons[currentWinningCondition[j][3]]["player"]
              : (matrixSize == "Five"
                  ? buttons[currentWinningCondition[j][2]]["player"] ==
                          buttons[currentWinningCondition[j][3]]["player"] &&
                      buttons[currentWinningCondition[j][3]]["player"] ==
                          buttons[currentWinningCondition[j][4]]
                              ["player"] // For 5x5
                  : true)) &&
          buttons[currentWinningCondition[j][0]]["player"] != "0") {
        winner = buttons[currentWinningCondition[j][0]]["player"];

        if (called == 0 && winner != "0") {
          onWin!(j);
          called += 1;
        }
      }
    }

    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null && buttons[i]["player"] != "0") {
        _count++;
      }
    }

// Check for a tie condition
    if (_count ==
            (matrixSize == "Three"
                ? 9
                : (matrixSize == "Four" ? 16 : 25)) && // Updated for 5x5
        winner == "0" &&
        tieCalled == 0) {
      tieCalled++;
      // Notify that the game is a tie
      if (onTie != null) onTie(0);
    }
  }

  getPlayerNameByUid(uid) async {
    DatabaseEvent ref = await _userRef.child(uid).once();
    var result = (ref.snapshot.value as Map)["username"];
    return result;
  }

  updateMatchWonCount(String id) async {
    DatabaseEvent playerData = await _userRef.child(id).once();
    var matchWonCount = (playerData.snapshot.value as Map)["matchwon"];
    var newMatchwonCount = matchWonCount + 1;
    _userRef.child(id).update({"matchwon": newMatchwonCount});

    var matchPlayedCount = (playerData.snapshot.value as Map)["matchplayed"];
    var newMatchPlayedCount = matchPlayedCount + 1;
    _userRef.child(id).update({"matchplayed": newMatchPlayedCount});
  }

  updateMatchPlayedCount(BuildContext context, String id, [matchResult]) async {
    DatabaseEvent playerData = await _userRef.child(id).once();

    //update match count
    var matchPlayedCount = (playerData.snapshot.value as Map)["matchplayed"];
    var updatedMatchPlayedCount = matchPlayedCount + 1;
    _userRef.child(id).update({"matchplayed": updatedMatchPlayedCount});

    //update score
    if (matchResult != "" && matchResult != null) {
      var currentscore = (playerData.snapshot.value as Map)["score"];
      var updatedScore;

      if (matchResult == utils.getTranslated(context, "tie")) {
        updatedScore = currentscore + tieScore;
      } else if (matchResult == utils.getTranslated(context, "win")) {
        updatedScore = currentscore + winScore;
      } else {
        updatedScore = currentscore - loseScore;
      }

      _userRef.child(id).update({"score": updatedScore});
    }
  }

  static dispose() {
    _stream?.cancel();
  }
}
