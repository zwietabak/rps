pragma solidity ^0.4.18;

contract Owned {
  address owner;

  function Owned() {
    owner = msg.sender;
  }

  function kill() {
    if(msg.sender == owner) selfdestruct(owner);
  }
}

contract RPS is Owned {
  int public numberPlayers = 0;
  int maxNumberPlayers = 2;
  uint betWei;
  uint public winPrice = 0;
  uint ROCK = 0;
  uint PAPER = 1;
  uint SCISSOR = 2;

  Player[] public player;
  Status public gameStatus = Status(0, "Noch keine Wetten plaziert!");

  event eventPublishStatus(string message);

  struct Player {
    address walletAddress;
    string name;
    uint bet;
    bool winner;
  }

  struct Status {
      uint id;
      string message;
  }

  function RPS(uint betEther) {
    //betWei = betEther * 1000000000000000000;
    // Eingabe: 3 -> 0,000003
    betWei = betEther * 1000000000000;
  }

  function makeBet(string _playerName, uint choise) payable returns (bool) {
    address playerAddress = msg.sender;
    bytes memory playerName = bytes(_playerName);

    //Hat der Spieler genug Geld?
    if (msg.value < betWei) return false;

    //Spiel hat bereits gestartet
    if (gameStatus.id >= 2) return false;

    //Der Spielername muss min 1 Zeichen haben
    if (playerName.length < 1) return false;

    player.push(Player(playerAddress, _playerName, choise, false));
    numberPlayers++;
    winPrice += msg.value;

    if (numberPlayers < maxNumberPlayers) {
      gameStatus.id = 1;
    } else if (numberPlayers == maxNumberPlayers) {
      gameStatus.id = 2;
    }

    eventPublishStatus(getStatus());
    return true;
  }

  function playGame() {
    if(gameStatus.id == 2) {
      if ((player[0].bet == ROCK && player[1].bet == SCISSOR) ||
         (player[0].bet == PAPER && player[1].bet == ROCK) ||
         (player[0].bet == SCISSOR && player[1].bet == PAPER)) {
            player[0].winner = true;
      } else if ((player[1].bet == ROCK && player[0].bet == SCISSOR) ||
                 (player[1].bet == PAPER && player[0].bet == ROCK) ||
                 (player[1].bet == SCISSOR && player[0].bet == PAPER)) {
            player[1].winner = true;
      }

      if (player[0].winner == true && player[1].winner == false) {
        if (player[0].walletAddress.send(winPrice)) gameStatus.id = 3;
      } else if (player[0].winner == false && player[1].winner == true) {
        if (player[1].walletAddress.send(winPrice)) gameStatus.id = 3;
      } else {
        if ((player[0].walletAddress.send(betWei)) && (player[1].walletAddress.send(betWei))) gameStatus.id = 4;
      }
      //emit eventPublishStatus(getStatus());
    }
  }

  function getWinner() view returns (string) {
    if(player[0].winner) {
        return player[0].name;
    } else if(player[1].winner) {
        return player[1].name;
    } else if(!player[0].winner && !player[1].winner) {
        return "DRAW!";
    }
  }

  function resetGame() public {
    if(gameStatus.id > 0) {
        for(int i = 0; i < numberPlayers; i++) {
            delete player[uint(i)];
        }
        gameStatus.id = 0;
        numberPlayers = 0;
        winPrice = 0;
    }
  }

  function getStatus() view returns (string) {
    if(gameStatus.id == 0) gameStatus.message = "Noch keine Wetten plaziert";
    if(gameStatus.id == 1) gameStatus.message = "Ein Spieler hat einen Tipp abgegeben";
    if(gameStatus.id == 2) gameStatus.message = "Beide Spieler haben gewettet\nLET THE GAME BEGIN!";
    if(gameStatus.id == 3) gameStatus.message = "Es gibt einen Gewinner";
    if(gameStatus.id == 4) gameStatus.message = "DRAW...";

    return (gameStatus.message);
  }
}
