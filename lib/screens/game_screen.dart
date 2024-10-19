import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hangman/components/word_button.dart';
import 'package:flutter_hangman/screens/home_screen.dart';
import 'package:flutter_hangman/utilities/alphabet.dart';
import 'package:flutter_hangman/utilities/constants.dart';
import 'package:flutter_hangman/utilities/hangman_words.dart';
import 'package:flutter_hangman/utilities/quote_model.dart';
import 'package:flutter_hangman/utilities/score_db.dart' as score_database;
import 'package:flutter_hangman/utilities/user_coins.dart';
import 'package:flutter_hangman/utilities/user_scores.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'dart:io';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.hangmanObject});

  final HangmanWords hangmanObject;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final database = score_database.openDB();
  int lives = 3;
  Alphabet englishAlphabet = Alphabet(); // lista de letras alfabeticas
  late String word;
  late String hiddenWord = ''; // pontilhados com as letras escondidas
  List<String> wordList = []; // palavra transformada em lista de letra
  List<int> hintLetters = []; // copia da wordlist, porem com os indexes
  late List<bool> buttonStatus; // estatdo de cada botão, se foi pressionado ou não
  late bool hintStatus;
  int hangState = 0; // estado do desenho/img do boneco enforcado
  int wordCount = 0; // contagem de palavras acertadas
  bool finishedGame = false;
  bool resetGame = false;
  int coins = -1;
  QuoteModel? quote;
  

  
  void newGame() {
    setState(() {
      widget.hangmanObject.resetWords();
      englishAlphabet = Alphabet();
      lives = 3;
      wordCount = 0;
      finishedGame = false;
      resetGame = false;
      initWords();
    });
  }

  void initCoins() async {
    // var db = score_database.openDB();
    try {
      
      List<Coin> queryResult = await score_database.getCoins(database);
      if (queryResult.isNotEmpty) {
      
        coins = queryResult.first.userCoins; //buscar valor do banco
      } else {
      
        score_database.upsertCoins(Coin(coinDate: DateTime.now().toString(), userCoins: 10), database); // cria no banco com valor 10
        coins = 10;
      }
    } catch (e) {
      debugPrint("---> $e");
    }

    setState(() {});
  }

  Widget createButton(index) {
    if (!buttonStatus[index]) {
      // se o botão já foi clicado, apaga o botao
      return const SizedBox();
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 3.0),
        child: Center(
          child: WordButton(
            buttonTitle: englishAlphabet.alphabet[index].toUpperCase(),
            onPress: buttonStatus[index] ? () => wordPress(index) : () {},
          ),
        ),
      );
    }
  }

  void returnHomePage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      ModalRoute.withName('homePage'),
    );
  }

  void initWords() async {
    finishedGame = false;
    resetGame = false;
    hintStatus = true;
    hangState = 0;
    buttonStatus = List.generate(26, (index) {
      return true;
    });
    wordList = [];
    hintLetters = [];
    word = widget.hangmanObject.getWord();    

    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        quote = await widget.hangmanObject.getQuote();
        word = quote!.word;
      }
    } catch (e) {
      //
    }
    setState(() {});

    if (word.isNotEmpty) {
      hiddenWord = widget.hangmanObject.getHiddenWord(word.length);
    } else {
      returnHomePage();
    }

    for (int i = 0; i < word.length; i++) {
      wordList.add(word[i]);
      hintLetters.add(i);
    }
  }

  void wordPress(int index) {
    if (lives == 0) {
      // checa se ainda tem vidas
      returnHomePage();
    }

    if (finishedGame) {
      // reseta se game finalizado
      setState(() {
        resetGame = true;
      });
      return;
    }

    bool check = false;

    setState(() {
      for (int i = 0; i < wordList.length; i++) {
        // se a letra for correta, substitui o _ pela letra

        if (wordList[i] == englishAlphabet.alphabet[index]) {
          check = true;
          wordList[i] = '';
          hiddenWord = hiddenWord.replaceFirst(RegExp('_'), word[i], i);
        }
      }

      for (int i = 0; i < wordList.length; i++) {
        if (wordList[i] == '') {
          hintLetters.remove(i);
        }
      }

      if (!check) {
        hangState += 1;
      }

      if (hangState == 6) {
        // fail the game
        hiddenWord = '';
        quote = null;
        finishedGame = true;
        lives -= 1;
        if (lives < 1) {
          if (wordCount > 0) {
            Score score = Score(id: 1, scoreDate: DateTime.now().toString(), userScore: wordCount);
            score_database.manipulateDatabase(score, database);
            saveCoinsInDatabase();
          }
          Alert(style: kGameOverAlertStyle, context: context, title: "Game Over!", desc: "Your score is $wordCount", buttons: [
            DialogButton(
              color: kDialogButtonColor,
              onPressed: () => returnHomePage(),
              child: Icon(
                MdiIcons.home,
                size: 30.0,
              ),
            ),
            DialogButton(
              onPressed: () {
                newGame();
                Navigator.pop(context);
              },
              color: kDialogButtonColor,
              child: Icon(MdiIcons.refresh, size: 30.0),
            ),
          ]).show();
        } else {
          Alert(
            context: context,
            style: kFailedAlertStyle,
            type: AlertType.error,
            title: "Fail",
            desc: "The word was: $word",
            buttons: [
              DialogButton(
                radius: BorderRadius.circular(10),
                width: 127,
                color: kDialogButtonColor,
                height: 52,
                child: Icon(
                  MdiIcons.arrowRightThick,
                  size: 30.0,
                ),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                    initWords();
                  });
                },
              ),
            ],
          ).show();
        }
      }

      buttonStatus[index] = false;
      print('==== $word');
      saveCoinsInDatabase();
      if (hiddenWord.toLowerCase().trim() == word.toLowerCase().trim()) {
        // won the game
        hiddenWord = '';
        quote = null;
        finishedGame = true;
        Alert(
          context: context,
          style: kSuccessAlertStyle,
          type: AlertType.success,
          title: word,
//          desc: "You guessed it right!",
          buttons: [
            DialogButton(
              radius: BorderRadius.circular(10),
              width: 127,
              color: kDialogButtonColor,
              height: 52,
              child: Icon(
                MdiIcons.arrowRightThick,
                size: 30.0,
              ),
              onPressed: () {
                setState(() {
                  wordCount += 1;
                  Navigator.pop(context);
                  saveCoinsInDatabase();
                  initWords();
                });
              },
            )
          ],
        ).show();
      }
    });
  }

  void showContext() {
    Alert(style: kGameOverAlertStyle, context: context, title: "Context", desc: quote!.quoteHidden, buttons: [
      DialogButton(
        radius: BorderRadius.circular(10),
        width: 127,
        color: kDialogButtonColor,
        height: 52,
        child: Icon(
          MdiIcons.arrowRightThick,
          size: 30.0,
        ),
        onPressed: () {
          setState(() {
            Navigator.pop(context);
          });
        },
      ),
    ]).show();
  }

  void earnCoins() {
    Alert(style: kGameOverAlertStyle, context: context, title: "Coins", desc: "Watch ad for 15 coins", buttons: [
      DialogButton(
        radius: BorderRadius.circular(10),
        width: 127,
        color: kDialogButtonColor,
        height: 52,
        child: Icon(
          MdiIcons.televisionPlay,
          size: 30.0,
        ),
        onPressed: () {
          setState(() {
            Navigator.pop(context);
          });
        },
      ),
      DialogButton(
        radius: BorderRadius.circular(10),
        width: 127,
        color: kDialogButtonColor,
        height: 52,
        child: const Icon(
          Icons.cancel,
          size: 30.0,
        ),
        onPressed: () {
          setState(() {
            Navigator.pop(context);
          });
        },
      ),
    ]).show();
  }

  void saveCoinsInDatabase() {
    score_database.upsertCoins(Coin(coinDate: DateTime.now().toString(), userCoins: coins), database);
  }

  @override
  void initState() {
    super.initState();    
    initWords();
    initCoins();
  }

  @override
  Widget build(BuildContext context) {
    if (resetGame) {
      setState(() {
        initWords();
      });
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(            
            children: <Widget>[
              Expanded(
                  flex: 4,
                  child: Column(                                  
                    children: <Widget>[
                      
                      // row de botoes icon
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6.0, 8.0, 6.0, 35.0),                        
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                // Exibição vidas
                                Stack(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.only(top: 0.5),
                                      child: Column(
                                        children: [
                                          IconButton(
                                            tooltip: 'Lives',
                                            highlightColor: Colors.transparent,
                                            splashColor: Colors.transparent,
                                            iconSize: 39,
                                            icon: Icon(MdiIcons.heart),
                                            onPressed: () {},
                                          ),
                                          Column(
                                            children: [
                                              IconButton(
                                                tooltip: 'Coins',
                                                highlightColor: Colors.transparent,
                                                splashColor: Colors.transparent,
                                                iconSize: 39,
                                                icon: Column(
                                                  children: [
                                                    const Icon(
                                                      FontAwesomeIcons.coins,
                                                      size: 25,
                                                    ),
                                                    Text(
                                                      '$coins',
                                                      style: const TextStyle(fontSize: 20, color: Colors.white),
                                                    )
                                                  ],
                                                ),
                                                onPressed: earnCoins,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(8.7, 7.9, 0, 0.8),
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        height: 38,
                                        width: 38,
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: Text(
                                              lives.toString() == "1" ? "I" : lives.toString(),
                                              style: const TextStyle(
                                                color: Color(0xFF2C1E68),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'PatrickHand',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                  
                            // contador de palavras acertadas
                            SizedBox(
                              child: Text(
                                '$wordCount',
                                style: kWordCounterTextStyle,
                              ),
                            ),
                  
                            // botão de dica
                            SizedBox(
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      IconButton(
                                          tooltip: 'Context',
                                          iconSize: 39,
                                          icon: Icon(MdiIcons.tooltipQuestion),
                                          highlightColor: Colors.transparent,
                                          splashColor: Colors.transparent,
                                          onPressed: (coins < 7 || quote == null)
                                              ? null
                                              : () {
                                                  showContext();
                                                  coins -= 7;
                                                }),
                                      const Text(
                                        "7 coins",
                                        style: TextStyle(color: Colors.white),
                                      )
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                          tooltip: 'Hint',
                                          iconSize: 39,
                                          icon: Icon(MdiIcons.lightbulb),
                                          highlightColor: Colors.transparent,
                                          splashColor: Colors.transparent,
                                          onPressed: coins < 3
                                              ? null
                                              : () {
                                                  // seleciona uma letra aletoria e revela
                                                  try {
                                                    int rand = Random().nextInt(hintLetters.length);
                                                    wordPress(englishAlphabet.alphabet.indexOf(wordList[hintLetters[rand]]));
                                                    coins -= 3;
                                                  } catch (e) {
                                                    //pass
                                                  }
                                                }),
                                      const Text(
                                        "3 coins",
                                        style: TextStyle(color: Colors.white),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  
                      // renderização de boneco
                      Expanded(
                        flex: 3,
                        child: Transform.scale(
                          scale: .7,
                          child: Container(                                                                                 
                            alignment: Alignment.bottomCenter,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Image.asset(
                                'images/$hangState.png',
                                height: 1001,
                                width: 991,                              
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                  
                      // palavra pontilhada
                      Transform.scale(
                        scale: .9,
                        child: Container(     
                          // color: Colors.amber,
                          margin: const EdgeInsets.only(bottom: 20),
                                     
                          // margin: const EdgeInsets.symmetric(horizontal: 15.0),
                          alignment: Alignment.center,
                          // child: FittedBox(
                          //   fit: BoxFit.fitWidth,
                          //   child: Text(
                          //     hiddenWord,
                          //     style: kWordTextStyle,
                          //   ),
                          // ),
                          child: Text(
                            hiddenWord,
                            style: kWordTextStyle,
                          ),
                        ),
                      ),
                    ],
                  )),

              // list of letters
              Expanded(
                flex: 2,
                child: Transform.scale(
                  scale: .95,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10.0, 2.0, 8.0, 10.0),                    
                    child: Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      //columnWidths: {1: FlexColumnWidth(10)},
                      children: [
                        TableRow(children: [
                          
                          TableCell(
                            child: createButton(0),
                          ),
                          TableCell(
                            child: createButton(1),
                          ),
                          TableCell(
                            child: createButton(2),
                          ),
                          TableCell(
                            child: createButton(3),
                          ),
                          TableCell(
                            child: createButton(4),
                          ),
                          TableCell(
                            child: createButton(5),
                          ),
                          TableCell(
                            child: createButton(6),
                          ),
                        ]),
                        TableRow(children: [
                          TableCell(
                            child: createButton(7),
                          ),
                          TableCell(
                            child: createButton(8),
                          ),
                          TableCell(
                            child: createButton(9),
                          ),
                          TableCell(
                            child: createButton(10),
                          ),
                          TableCell(
                            child: createButton(11),
                          ),
                          TableCell(
                            child: createButton(12),
                          ),
                          TableCell(
                            child: createButton(13),
                          ),
                        ]),
                        TableRow(children: [
                          TableCell(
                            child: createButton(14),
                          ),
                          TableCell(
                            child: createButton(15),
                          ),
                          TableCell(
                            child: createButton(16),
                          ),
                          TableCell(
                            child: createButton(17),
                          ),
                          TableCell(
                            child: createButton(18),
                          ),
                          TableCell(
                            child: createButton(19),
                          ),
                          TableCell(
                            child: createButton(20),
                          ),
                        ]),
                        TableRow(children: [
                          TableCell(
                            child: createButton(21),
                          ),
                          TableCell(
                            child: createButton(22),
                          ),
                          TableCell(
                            child: createButton(23),
                          ),
                          TableCell(
                            child: createButton(24),
                          ),
                          TableCell(
                            child: createButton(25),
                          ),
                          const TableCell(
                            child: Text(''),
                          ),
                          const TableCell(
                            child: Text(''),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            
            ],
          ),
        ),          
      ),
    );
  }
}
