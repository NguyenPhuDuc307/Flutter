class Player {
  final String name;
  int score;
  final List<int> lostBalls;
  final List<int> wonBalls;

  Player({
    required this.name,
    this.score = 0,
  })  : lostBalls = [],
        wonBalls = [];

  void addLostBall(int ball) {
    lostBalls.add(ball);
  }

  void addWonBall(int ball) {
    wonBalls.add(ball);
  }

  void reset() {
    score = 0;
    lostBalls.clear();
    wonBalls.clear();
  }
}
