import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../models/player.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int raceToScore;
  final int handicap;
  final int numberOfPlayers;
  final List<String> playerNames;

  const GameScreen({
    super.key,
    required this.mode,
    this.raceToScore = 5,
    this.handicap = 0,
    this.numberOfPlayers = 2,
    this.playerNames = const [],
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<Player> players;
  int? selectedPlayerIndex;
  List<Map<String, dynamic>> actionHistory = [];
  List<Map<String, dynamic>> gameHistory = [];
  bool isHistoryExpanded = false;
  int? lastHighBallWinner; // Người ăn bi 9/10 cuối cùng
  int? lastHighBallVictim; // Người bị ăn bi 9/10 cuối cùng

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  void _saveState(String actionType) {
    // Lưu trạng thái hiện tại trước khi thay đổi
    actionHistory.add({
      'type': actionType,
      'players': players
          .map((p) => {
                'name': p.name,
                'score': p.score,
                'lostBalls': List<int>.from(p.lostBalls),
                'wonBalls': List<int>.from(p.wonBalls),
              })
          .toList(),
    });
  }

  void _undo() {
    if (actionHistory.isEmpty) return;

    setState(() {
      final lastState = actionHistory.removeLast();
      final savedPlayers = lastState['players'] as List;

      for (int i = 0; i < players.length; i++) {
        players[i].score = savedPlayers[i]['score'];
        players[i].lostBalls.clear();
        players[i]
            .lostBalls
            .addAll(List<int>.from(savedPlayers[i]['lostBalls']));
        players[i].wonBalls.clear();
        players[i].wonBalls.addAll(List<int>.from(savedPlayers[i]['wonBalls']));
      }
    });
  }

  void _newGame() {
    // Lưu ván hiện tại vào lịch sử (không reset điểm)
    if (actionHistory.isNotEmpty || players.any((p) => p.score != 0)) {
      setState(() {
        gameHistory.insert(0, {
          'timestamp': DateTime.now(),
          'players': players
              .map((p) => {
                    'name': p.name,
                    'score': p.score,
                  })
              .toList(),
        });
        // Clear action history và reset bi đã ăn/mất
        actionHistory.clear();
        selectedPlayerIndex = null;
        lastHighBallWinner = null;
        lastHighBallVictim = null;

        // Reset bi đã ăn/mất cho tất cả người chơi
        for (var player in players) {
          player.lostBalls.clear();
          player.wonBalls.clear();
        }
      });
    }
  }

  int? _getPlayOrder(int playerIndex) {
    // Tính thứ tự chơi cho người chơi
    List<int> order = [];

    // 1. Người ăn bi 9/10 đánh trước
    if (lastHighBallWinner != null) {
      order.add(lastHighBallWinner!);
    }

    // 2. Người bị ăn bi 9/10 đánh tiếp
    if (lastHighBallVictim != null &&
        lastHighBallVictim != lastHighBallWinner) {
      order.add(lastHighBallVictim!);
    }

    // 3. Những người còn lại, sắp xếp theo số bi mất (nhiều nhất trước)
    List<int> remainingPlayers = [];
    for (int i = 0; i < players.length; i++) {
      if (i != lastHighBallWinner && i != lastHighBallVictim) {
        remainingPlayers.add(i);
      }
    }

    // Sắp xếp theo số bi đã mất (nhiều nhất trước)
    remainingPlayers.sort((a, b) {
      int aLost = players[a].lostBalls.length;
      int bLost = players[b].lostBalls.length;
      return bLost.compareTo(aLost);
    });

    order.addAll(remainingPlayers);

    // Tìm vị trí của người chơi trong thứ tự
    int position = order.indexOf(playerIndex);
    return position >= 0 ? position + 1 : null;
  }

  void _initializePlayers() {
    players = List.generate(
      widget.numberOfPlayers,
      (index) => Player(
        name: widget.playerNames.isNotEmpty && index < widget.playerNames.length
            ? widget.playerNames[index]
            : 'P${index + 1}',
        score: index == 1 && widget.mode == GameMode.solo ? widget.handicap : 0,
      ),
    );
  }

  void _addScore(int playerIndex, int points) {
    _saveState('addScore');
    setState(() {
      final newScore = players[playerIndex].score + points;
      // Nếu là solo, không cho điểm vượt quá raceToScore
      if (widget.mode == GameMode.solo && points > 0) {
        players[playerIndex].score =
            newScore > widget.raceToScore ? widget.raceToScore : newScore;
      } else {
        players[playerIndex].score = newScore;
      }
    });
  }

  void _handleSpecialBall(int playerIndex, int ball) async {
    final points = widget.mode.getPointsForBall(ball);

    // Hiện dialog chọn người bị đền
    final victimIndex = await _showSelectVictimDialog(playerIndex, ball);

    if (victimIndex != null) {
      _saveState('specialBall');
      setState(() {
        // Người ăn được cộng điểm và đánh dấu bi đã ăn
        players[playerIndex].score += points;
        players[playerIndex].addWonBall(ball);
        // Người bị đền trừ điểm và đánh dấu bi đã mất
        players[victimIndex].score -= points;
        players[victimIndex].addLostBall(ball);

        // Lưu lại người ăn bi cao nhất (9 hoặc 10)
        final highBall = widget.mode.specialBalls.last;
        if (ball == highBall) {
          lastHighBallWinner = playerIndex;
          lastHighBallVictim = victimIndex;
        }
      });
    }
  }

  void _handleChamDon(int playerIndex) async {
    // Chọn người bị đền cho chấm đơn
    final victimIndex = await _showSelectVictimForChamDonDialog(playerIndex);

    if (victimIndex != null) {
      _saveState('chamDon');

      // Tính tổng điểm tất cả bi đặc biệt x 2
      final specialBalls = widget.mode.specialBalls;
      int totalBallPoints = 0;
      for (int ball in specialBalls) {
        totalBallPoints += widget.mode.getPointsForBall(ball);
      }
      final chamDonPoints = totalBallPoints * 2;

      setState(() {
        // Người ăn được cộng điểm và đánh dấu tất cả bi đã ăn (mỗi bi 2 lần)
        players[playerIndex].score += chamDonPoints;
        for (int ball in specialBalls) {
          players[playerIndex].addWonBall(ball);
          players[playerIndex].addWonBall(ball); // Thêm lần 2 vì gấp đôi
        }

        // Người bị đền trừ điểm và đánh dấu tất cả bi đã mất (mỗi bi 2 lần)
        players[victimIndex].score -= chamDonPoints;
        for (int ball in specialBalls) {
          players[victimIndex].addLostBall(ball);
          players[victimIndex].addLostBall(ball); // Thêm lần 2 vì gấp đôi
        }

        // Lưu lại người ăn bi cao nhất
        final highBall = widget.mode.specialBalls.last;
        lastHighBallWinner = playerIndex;
        lastHighBallVictim = victimIndex;
      });
    }
  }

  Future<int?> _showSelectVictimForChamDonDialog(int attackerIndex) async {
    // Tính điểm chấm đơn
    final specialBalls = widget.mode.specialBalls;
    int totalBallPoints = 0;
    for (int ball in specialBalls) {
      totalBallPoints += widget.mode.getPointsForBall(ball);
    }
    final chamDonPoints = totalBallPoints * 2;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 4),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${players[attackerIndex].name}\nCHẤM ĐƠN',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'NGƯỜI BỊ ĐỀN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < players.length; i++)
                  if (i != attackerIndex) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context, i),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          border: Border.all(color: Colors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '${players[i].name} (-$chamDonPoints)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: const Text(
                      'HỦY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int?> _showSelectVictimDialog(int attackerIndex, int ball) async {
    final points = widget.mode.getPointsForBall(ball);

    return showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 4),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${players[attackerIndex].name}\nĂN BI $ball',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'NGƯỜI BỊ ĐỀN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < players.length; i++)
                  if (i != attackerIndex) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context, i),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          border: Border.all(color: Colors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '${players[i].name} (-$points)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: const Text(
                      'HỦY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleBreakAndRun(int playerIndex) {
    _saveState('breakAndRun');
    // Tính tổng điểm tất cả bi đặc biệt
    final specialBalls = widget.mode.specialBalls;
    int totalBallPoints = 0;
    for (int ball in specialBalls) {
      totalBallPoints += widget.mode.getPointsForBall(ball);
    }

    setState(() {
      int totalGain = 0;
      // Mỗi đối thủ bị trừ gấp đôi tổng điểm bi
      final penaltyPerPlayer = totalBallPoints * 2;

      for (int i = 0; i < players.length; i++) {
        if (i != playerIndex) {
          players[i].score -= penaltyPerPlayer;
          totalGain += penaltyPerPlayer;

          // Đánh dấu tất cả bi đã mất (mỗi bi 2 lần vì gấp đôi)
          for (int ball in specialBalls) {
            players[i].addLostBall(ball);
            players[i].addLostBall(ball);
          }
        }
      }

      // Người phá được cộng tổng số điểm tất cả đối thủ bị trừ
      players[playerIndex].score += totalGain;

      // Đánh dấu tất cả bi đã ăn (mỗi bi 2 lần vì gấp đôi, nhân số đối thủ)
      for (int i = 0; i < players.length; i++) {
        if (i != playerIndex) {
          for (int ball in specialBalls) {
            players[playerIndex].addWonBall(ball);
            players[playerIndex].addWonBall(ball);
          }
        }
      }

      // Lưu lại người ăn bi cao nhất
      final highBall = widget.mode.specialBalls.last;
      lastHighBallWinner = playerIndex;
      lastHighBallVictim = null; // Không có victim cụ thể
    });
  }

  void _resetGame() {
    setState(() {
      _initializePlayers();
      selectedPlayerIndex = null;
      actionHistory.clear();
      gameHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSolo = widget.mode == GameMode.solo;

    return PopScope(
      canPop: false, // Chặn nút back
      onPopInvoked: (didPop) {
        if (!didPop) {
          _confirmExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(86),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      // Nút Kết thúc
                      GestureDetector(
                        onTap: _confirmExit,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút Undo
                      if (actionHistory.isNotEmpty)
                        GestureDetector(
                          onTap: _undo,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.undo,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      if (actionHistory.isNotEmpty) const SizedBox(width: 8),
                      // Nút Ván mới
                      GestureDetector(
                        onTap: _newGame,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút Reset
                      GestureDetector(
                        onTap: _resetGame,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (isSolo) _buildSoloView() else _buildDenView(),
              if (gameHistory.isNotEmpty) _buildGameHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 4),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'KẾT THÚC?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn có chắc muốn kết thúc?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(4, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'HỦY',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(4, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'KẾT THÚC',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldExit == true) {
      Navigator.pop(context);
    }
  }

  Widget _buildGameHistory() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: isHistoryExpanded ? 600 : 200,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(
          top: BorderSide(color: Colors.white, width: 3),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isHistoryExpanded = !isHistoryExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'LỊCH SỬ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isHistoryExpanded ? Icons.expand_more : Icons.expand_less,
                    color: Colors.black,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: gameHistory.length,
              itemBuilder: (context, index) {
                final game = gameHistory[index];
                final gamePlayers = game['players'] as List;
                final timestamp = game['timestamp'] as DateTime;

                return Dismissible(
                  key: Key('game_$index${timestamp.millisecondsSinceEpoch}'),
                  direction: index == 0
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  confirmDismiss: (direction) async {
                    if (index != 0)
                      return false; // Chỉ cho phép xóa ván đầu tiên

                    return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 4),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'XÓA VÁN NÀY?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            Navigator.pop(context, false),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            border: Border.all(
                                                color: Colors.black, width: 3),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black,
                                                offset: Offset(3, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'HỦY',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            Navigator.pop(context, true),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            border: Border.all(
                                                color: Colors.black, width: 3),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black,
                                                offset: Offset(3, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'XÓA',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    setState(() {
                      gameHistory.removeAt(index);

                      print('=== DEBUG: Xóa ván ===');
                      print(
                          'Số ván còn lại trong lịch sử: ${gameHistory.length}');

                      // Nếu còn ván trong lịch sử, quay về ván mới nhất
                      if (gameHistory.isNotEmpty) {
                        final previousGame = gameHistory[0];
                        final previousPlayers = previousGame['players'] as List;

                        print('Quay về ván trước đó:');
                        for (var p in previousPlayers) {
                          print('  ${p['name']}: ${p['score']}');
                        }

                        for (int i = 0;
                            i < players.length && i < previousPlayers.length;
                            i++) {
                          players[i].score = previousPlayers[i]['score'];
                          players[i].lostBalls.clear();
                        }
                      } else {
                        // Không còn ván nào, reset về 0
                        print('Không còn ván nào, reset về điểm ban đầu');
                        for (int i = 0; i < players.length; i++) {
                          players[i].score =
                              i == 1 && widget.mode == GameMode.solo
                                  ? widget.handicap
                                  : 0;
                          players[i].lostBalls.clear();
                        }
                      }

                      print('Điểm sau khi khôi phục:');
                      for (int i = 0; i < players.length; i++) {
                        print('  ${players[i].name}: ${players[i].score}');
                      }

                      // Clear action history vì đã quay về ván trước
                      actionHistory.clear();
                    });
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            for (var player in gamePlayers)
                              Row(
                                children: [
                                  Text(
                                    '${player['name']}: ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow,
                                      border: Border.all(
                                          color: Colors.black, width: 2),
                                    ),
                                    child: Text(
                                      '${player['score']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoloView() {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: _buildPlayerCard(0, Colors.yellow),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Text(
              'RACE TO ${widget.raceToScore}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _buildPlayerCard(1, Colors.cyan),
          ),
        ],
      ),
    );
  }

  Widget _buildDenView() {
    // Sắp xếp người chơi theo điểm từ cao xuống thấp
    final sortedPlayers = List<int>.generate(players.length, (i) => i)
      ..sort((a, b) => players[b].score.compareTo(players[a].score));

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (int i = 0; i < sortedPlayers.length; i++) ...[
                _buildDenPlayerCard(sortedPlayers[i]),
                if (i < sortedPlayers.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(int index, Color color) {
    final player = players[index];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            player.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            player.score.toString(),
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildButton('-', Colors.white, () {
                    _addScore(index, -1);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton('+', Colors.white, () {
                    _addScore(index, 1);
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDenPlayerCard(int index) {
    final player = players[index];
    final colors = [Colors.yellow, Colors.cyan, Colors.green, Colors.orange];
    final color = colors[index % colors.length];
    final isSelected = selectedPlayerIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlayerIndex = isSelected ? null : index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Colors.red : Colors.white,
            width: isSelected ? 6 : 4,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    if (_getPlayOrder(index) != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Text(
                          '(${_getPlayOrder(index)})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  player.score.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
              ],
            ),
            if (player.lostBalls.isNotEmpty || player.wonBalls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (player.wonBalls.isNotEmpty) ...[
                    for (int ball in player.wonBalls)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Text(
                          '$ball',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                  if (player.lostBalls.isNotEmpty) ...[
                    for (int ball in player.lostBalls)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Text(
                          '$ball',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
            if (isSelected) ...[
              const SizedBox(height: 12),
              _buildActionButtons(index),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(int playerIndex) {
    final specialBalls = widget.mode.specialBalls;

    return Column(
      children: [
        Row(
          children: [
            for (int ball in specialBalls) ...[
              Expanded(
                child: _buildButton(
                  'BI $ball',
                  Colors.white,
                  () => _handleSpecialBall(playerIndex, ball),
                ),
              ),
              if (ball != specialBalls.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildButton(
                'CHẤM ĐƠN',
                Colors.orange,
                () => _handleChamDon(playerIndex),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildButton(
                'BREAK & RUN',
                Colors.purple,
                () => _handleBreakAndRun(playerIndex),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
