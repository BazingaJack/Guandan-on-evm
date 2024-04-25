// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract Guandan {
    
    address public admin;
    uint public nextGameId;
    uint[] public deck;
    uint public globalSalt;

    enum cardType {
        unknown,
        single,
        pairs,
        tripleSingle,
        fourBoom,
        rocket,
        fiveBoom,
        triplePlusPairs,
        sameColorStraight,
        straight,
        sixBoom,
        triplePair,
        twoTripleSingle
    }
    
    struct player {
        address addr;
        uint level;
        uint roundRank;
        uint finalRank;
        uint order;
        address teammateAddr;
        uint maxCard;
        uint used;
        bool isValid;
    }

    struct card {
        uint cardId;
        uint num;//1-13
        uint color;//红黑草方王
        address owner;
        bool status;
    }

    struct cardArray {
        address sender;
        card[] cards;
    }

    struct round {
        uint roundId;
        uint level;
        uint lastNum;
        cardType lastType;
        address lastSender;
        bool isSwap;
        bool isOver;
        bool isValid;
    }

    struct game {
        uint gameId;
        uint roundId;
        address[] playerAddrs;
        address[] lastRoundOrder;
        address winer;
        uint status;//0-invalid 1-init 2-running 3-over
    }

    mapping(address => mapping(uint => card)) cardMap;
    mapping(address => player) players;
    mapping(uint => game) games;
    mapping(uint => mapping(uint => round)) gameRound; 

    modifier onlyOwner() {
        require(msg.sender == admin,"Only contract owner can call this function!");
        _;
    }

    constructor(){
        admin = msg.sender;
        nextGameId = 0;
        globalSalt = 0;
        for(uint i = 0;i < 108;i++){
            deck.push(i);
        }
    }

    function judgeBoom(card[] memory cards) public pure returns(bool) {
        for(uint i = 0;i < cards.length - 1;i++){
            if(cards[i].num != cards[i+1].num) return false;
        }
        return true;
    }

    function judgeStraight(card[] memory cards) public pure returns(bool,bool) {
        if(cards.length != 5) return (false,false);
        bool isValid = true;
        bool isSameColor = true;
        for(uint i = 0;i < 4;i++){
            if(cards[i].num + 1 != cards[i+1].num){
                isValid = false;
                break;
            }
            if(cards[i].color != cards[i+1].color) isSameColor = false;
        }
        return (isValid,isSameColor);
    }

    function judgeTriplePair(card[] memory cards) public pure returns(bool) {
        bool res = true;
        for(uint i = 0;i < 5;i = i + 2){
            if(cards[i].num != cards[i+1].num){
                res = false;
                break;
            }
        }
        if(cards[0].num == cards[2].num) res = false;
        if(cards[0].num == cards[4].num) res = false;
        if(cards[2].num == cards[4].num) res = false;
        return res;
    }

    function judgeTwoTripleSingle(card[] memory cards) public pure returns(bool) {
        bool res = true;
        for(uint i = 0;i < 5;i = i + 3){
            for(uint j = i;j < i + 2;j++){
                if(cards[j].num != cards[j+1].num){
                    res = false;
                    break;
                }
            }
            if(!res) break;
        }
        return res;
    }

    function judgeCardType(card[] memory cards) public pure returns (cardType cType, uint256 cardCount) {
        uint len = cards.length;
        if(len == 1){
            return (cardType.single,cards[0].num);
        }else if(len == 2){
            if(cards[0].num == cards[1].num) return (cardType.pairs,cards[0].num);
            else return (cardType.unknown,0);
        }else if(len == 3){
            if((cards[0].num == cards[1].num) && (cards[0].num == cards[2].num)) return (cardType.tripleSingle,cards[0].num);
            else return (cardType.unknown,0);
        }else if(len == 4){
            if(judgeBoom(cards)) return (cardType.fourBoom,cards[0].num);
            else if(cards[0].num + cards[1].num + cards[2].num + cards[3].num == 62) return (cardType.rocket,16);
            else return (cardType.unknown,0); 
        }else if(len == 5){
            if(judgeBoom(cards)) return (cardType.fiveBoom,cards[0].num);
            if(cards[0].num == cards[1].num && cards[0].num == cards[2].num && cards[3].num == cards[4].num) return (cardType.triplePlusPairs,cards[0].num);
            bool isValid;
            bool isSameColor;
            (isValid,isSameColor) = judgeStraight(cards);
            if(isValid){
                if(isSameColor) return (cardType.sameColorStraight,cards[0].num);
                else return (cardType.straight,cards[0].num);
            }
            return (cardType.unknown,0);
        }else if(len == 6){
            if(judgeBoom(cards)) return (cardType.sixBoom,cards[0].num);
            if(judgeTriplePair(cards)) return (cardType.triplePair,cards[0].num);
            if(judgeTwoTripleSingle(cards)) return (cardType.twoTripleSingle,cards[0].num);
        }else return (cardType.unknown,0);
    }

    function registerPlayer(address playerAddr) public onlyOwner {
        require(players[playerAddr].isValid == false,"This address has already been registered as a player.");
        player memory p = player(playerAddr,0,0,0,0,address(0),0,0,true);
        players[playerAddr] = p;
    }

    function checkPlayers(address[] memory playerAddrs) public view onlyOwner returns (bool){
        bool res = true;
        for(uint i = 0; i < playerAddrs.length;i++){
            if(players[playerAddrs[i]].isValid == false) {
                res = false;
                break;
            }
        }
        return res;
    }

    function randomTeammate(uint salt) public view returns(uint) {
        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp,salt))) % 3;
        return randomIndex;
    }

    function initGame(address[] memory playerAddrs) public onlyOwner{
        require(checkPlayers(playerAddrs) == true,"Player check failed.");
        game memory g = game(nextGameId,0,playerAddrs,playerAddrs,address(0),1);
        games[nextGameId] = g;
        nextGameId++;
        uint teamMate = randomTeammate(globalSalt);
        if(teamMate == 0){
            players[playerAddrs[0]].teammateAddr = playerAddrs[1];
            players[playerAddrs[1]].teammateAddr = playerAddrs[0]; 
            players[playerAddrs[2]].teammateAddr = playerAddrs[3]; 
            players[playerAddrs[3]].teammateAddr = playerAddrs[2]; 
        }else if(teamMate == 1){
            players[playerAddrs[0]].teammateAddr = playerAddrs[2];
            players[playerAddrs[2]].teammateAddr = playerAddrs[0]; 
            players[playerAddrs[1]].teammateAddr = playerAddrs[3]; 
            players[playerAddrs[3]].teammateAddr = playerAddrs[1]; 
        }else{
            players[playerAddrs[0]].teammateAddr = playerAddrs[3];
            players[playerAddrs[3]].teammateAddr = playerAddrs[0]; 
            players[playerAddrs[1]].teammateAddr = playerAddrs[2]; 
            players[playerAddrs[2]].teammateAddr = playerAddrs[1]; 
        }
    }

    function checkGameId(uint gameId) public view returns(bool) {
        return (games[gameId].status != 0 && games[gameId].status != 3);
    }

    function getCard(uint cardNum) public pure returns(uint,uint) {
        // 0-12 54-66 红桃2-A
        // 13-25 67-79 黑桃2-A
        // 26-38 80-92 梅花2-A
        // 39-51 93-105 方块2-A
        // 52-53 105-107 小/大王
        uint color = cardNum % 54 / 13;
        uint num = (cardNum % 54) % 13 + 2;
        if(color == 4){
            num += 13;
        }
        return (color,num);
    }

    function checkCardArray(address sender,cardArray memory cardArr) public view returns(bool) {
        uint arraySize = cardArr.cards.length;
        for(uint i = 0;i < arraySize;i++){
            if(cardMap[sender][cardArr.cards[i].cardId].owner != sender) return false;
        }
        return true;
    }

    function randomHandCard(address[] memory playerAddrs) public onlyOwner{
        require(deck.length >= 108, "Invalid deck length.");
        uint remaining = 128;
        for(uint i = 0;i < 27;i++){
            for(uint j = 0;j < 4;j++){
                uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp,i,j))) % remaining;
                uint cardNum = deck[randomIndex];
                deck[randomIndex] = deck[remaining - 1];
                remaining--;
                uint c;
                uint n;
                (c,n) = getCard(cardNum);
                card memory tempCard = card(i,c,n,playerAddrs[j],true);
                cardMap[playerAddrs[j]][i] = tempCard;
                if(n > players[playerAddrs[j]].maxCard) players[playerAddrs[j]].maxCard = n;
                if(i == 0) players[playerAddrs[j]].used = 0;
            }
        }
    }

    function initRound(uint gameId,address[] memory playerAddrs) public {
        require(games[gameId].status == 1 || games[gameId].status == 2,"This game doesn't exist or is over.");
        round memory r = round(games[gameId].roundId,2,0,cardType.unknown,address(0),false,false,true);
        gameRound[gameId][r.roundId] = r;
        games[gameId].roundId++;
        randomHandCard(playerAddrs);
    }

    function checkRoundId(uint gameId,uint roundId) public view returns(bool) {
        if(checkGameId(gameId) == false) return false;
        return (gameRound[gameId][roundId].isOver == false && gameRound[gameId][roundId].isValid == true);
    }

    function sendCardArray(uint gameId,uint roundId,address sender,cardArray memory cardArrs) public view returns(bool) {
        if(cardArrs.cards.length == 0) return true;
        require(checkRoundId(gameId,roundId) == true,"Invalid gameId and roundId.");
        require(checkCardArray(sender,cardArrs) == true,"Invalid card array.");
        cardType cType;
        uint cNum;
        (cType,cNum) = judgeCardType(cardArrs.cards);
        if(cType == cardType.unknown) return false;
        round memory r = gameRound[gameId][roundId];
        if(r.lastSender == sender){
            r.lastType = cType;
            r.lastNum = cNum;
        }else {
            if(cType != r.lastType) return false;
            else {
                if(cType == cardType.single){
                    if(cNum == r.level) return (r.lastNum < 15);
                }else return (cNum > r.lastNum);      
            }
        }
        return true;
    }

    function swapCard(uint gameId,uint roundId,address[] memory fromAddr,address[] memory toAddr,card[] memory cards,bool flag) public returns(bool) {
        require(checkRoundId(gameId,roundId) == true,"Invalid gameId and roundId.");
        require(fromAddr.length == toAddr.length && fromAddr.length == cards.length,"Must be same length.");
        bool res = true;
        if(games[gameId].status == 2) {
            game memory g = games[gameId];
            address[] memory order = g.lastRoundOrder;
            if(players[order[0]].teammateAddr == order[1]){
                if(flag) {
                    if(cardMap[order[2]][26].status == false || players[order[2]].maxCard != 16) return false;
                    if(cardMap[order[3]][26].status == false || players[order[3]].maxCard != 16) return false;
                }
                if(fromAddr.length != 4) return false;
                for(uint i = 0;i < 4;i++){
                    if(i == 0){
                        if(fromAddr[i] != order[0] || toAddr[i] != order[3] || cards[i].num > 10) return false;
                    }else if(i == 1){
                        if(fromAddr[i] != order[1] || toAddr[i] != order[2] || cards[i].num > 10) return false;
                    }else if(i == 2){
                        if(fromAddr[i] != order[2] || toAddr[i] != order[1] || players[order[2]].maxCard != cards[i].num) return false;
                    }else{
                        if(fromAddr[i] != order[3] || toAddr[i] != order[0] || players[order[3]].maxCard != cards[i].num) return false;
                    }
                }
            }else {
                if(fromAddr.length != 2) return false;
                if(fromAddr[0] != order[0] || toAddr[0] != order[3] || cards[0].num > 10) return false;
                if(fromAddr[1] != order[3] || toAddr[1] != order[0] || players[order[3]].maxCard != cards[1].num) return false;
            }
        }
        gameRound[gameId][roundId].isSwap = res;
        return res;
    }

    function roundProcess(uint gameId,uint roundId,address[] memory senderAddrs,cardArray[] memory arrays) public returns(bool,address[] memory){
        require(checkRoundId(gameId,roundId) == true,"Invalid gameId and roundId.");
        require(senderAddrs.length == arrays.length,"Must be same length.");
        require(gameRound[gameId][roundId].isSwap == true,"Must swap card first.");
        for(uint i = 0;i < senderAddrs.length;i++){
            if(sendCardArray(gameId, roundId, senderAddrs[i], arrays[i]) == false) return (false,games[gameId].lastRoundOrder);
            if(players[senderAddrs[i]].used == 27){
                games[gameId].lastRoundOrder.push(senderAddrs[i]);
            }
        }
        address[] memory order = games[gameId].lastRoundOrder;
        if(players[order[0]].teammateAddr == order[1]){
            players[order[0]].level += 3;
            players[order[1]].level += 3;
        }else if(players[order[0]].teammateAddr == order[2]){
            players[order[0]].level += 2;
            players[order[2]].level += 2;
        }else {
            players[order[0]].level += 1;
            players[order[3]].level += 1;
        }
        games[gameId].status = 2;
        if(players[order[0]].level >= 14) {
            games[gameId].status = 3;
            games[gameId].winer = order[0];
        }
        if(games[gameId].status == 2) delete games[gameId].lastRoundOrder;
        return(true,order);
    }

    function gameResultQuery(uint gameId) public view returns(bool,address,address) {
        require(checkGameId(gameId) == true,"Invalid gameId.");
        if(games[gameId].status != 3) return(false,address(0),address(0));
        else return (true,games[gameId].winer,players[games[gameId].winer].teammateAddr);
    }
}