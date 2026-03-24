enum GameMode {
  solo,
  den9Bi59,
  den9Bi369,
  den10Bi4710,
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.solo:
        return 'SOLO';
      case GameMode.den9Bi59:
        return 'ĐỀN 9 BI (5-9)';
      case GameMode.den9Bi369:
        return 'ĐỀN 9 BI (3-6-9)';
      case GameMode.den10Bi4710:
        return 'ĐỀN 10 BI (4-7-10)';
    }
  }

  List<int> get specialBalls {
    switch (this) {
      case GameMode.solo:
        return [];
      case GameMode.den9Bi59:
        return [5, 9];
      case GameMode.den9Bi369:
        return [3, 6, 9];
      case GameMode.den10Bi4710:
        return [4, 7, 10];
    }
  }

  int getPointsForBall(int ball) {
    switch (this) {
      case GameMode.solo:
        return 0;
      case GameMode.den9Bi59:
        if (ball == 5) return 1;
        if (ball == 9) return 2;
        return 0;
      case GameMode.den9Bi369:
        if (ball == 3) return 1;
        if (ball == 6) return 2;
        if (ball == 9) return 3;
        return 0;
      case GameMode.den10Bi4710:
        if (ball == 4) return 1;
        if (ball == 7) return 2;
        if (ball == 10) return 3;
        return 0;
    }
  }
}
