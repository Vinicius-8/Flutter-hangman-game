class Coin {
  final int? id;
  final String coinDate;
  final int userCoins;

  Coin({this.id, required this.coinDate, required this.userCoins});

  Map<String, dynamic> toMap() {
    return {
//      'id': id,
      'coinDate': coinDate,
      'userCoins': userCoins,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.

  @override
  String toString() {
    return '$userCoins,$coinDate,$id';
  }
}
