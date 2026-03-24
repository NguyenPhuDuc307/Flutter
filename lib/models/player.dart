class Player {
  final String name;
  int score;
  final List<int> lostBalls;

  Player({
    required this.name,
    this.score = 0,
  }) : lostBalls = [];

  void addLostBall(int ball) {
    if (!lostBalls.contains(ball)) {
      lostBalls.add(ball);
    }
  }

  void reset() {
    score = 0;
    lostBalls.clear();
  }
}
