// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract Guandan {
    
    address public admin;
    uint public nextGameId;
    uint[] public deck;

    enum cardType {
        init,
        unknown,
        single,
        pairs,
        triplePair,
        tripleSingle,
        twoTripleSingle,
        triplePlusPairs,
        straight,
        //上面是1类，下面是2类
        fourBoom,
        fiveBoom,
        sixBoom,
        sameColorStraight,
        rocket
    }
    
    struct player {
        address addr;
        uint level;
        uint roundRank;
        uint finalRank;
        uint order;
        address teammateAddr;
        bool isValid;
    }

    struct card {
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
        uint currentNum;
        cardType currentType;
        address currentSender;
        bool isOver;
        bool isValid;
    }

    struct game {
        uint gameId;
        uint roundId;
        address[] playerAddrs;
        address[] lastRoundOrder;
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

    function judgeCardType(card[] memory cards) public pure returns (cardType) {
        uint len = cards.length;
        if(len == 1){
            return (cardType.single);
        }else if(len == 2){
            if(cards[0].num == cards[1].num) return (cardType.pairs);
            else return (cardType.unknown);
        }else if(len == 3){
            if((cards[0].num == cards[1].num) && (cards[0].num == cards[2].num)) return (cardType.tripleSingle);
            else return (cardType.unknown);
        }else if(len == 4){
            if(judgeBoom(cards)) return (cardType.fourBoom);
            else if(cards[0].num + cards[1].num + cards[2].num + cards[3].num == 58) return (cardType.rocket);
            else return (cardType.unknown); 
        }else if(len == 5){
            if(judgeBoom(cards)) return cardType.fiveBoom;
            if(cards[0].num == cards[1].num && cards[0].num == cards[2].num && cards[3].num == cards[4].num) return cardType.triplePlusPairs;
            bool isValid;
            bool isSameColor;
            (isValid,isSameColor) = judgeStraight(cards);
            if(isValid){
                if(isSameColor) return cardType.sameColorStraight;
                else return cardType.straight;
            }
            return cardType.unknown;
        }else if(len == 6){
            if(judgeBoom(cards)) return cardType.sixBoom;
            if(judgeTriplePair(cards)) return cardType.triplePair;
            if(judgeTwoTripleSingle(cards)) return cardType.twoTripleSingle;
        }else return cardType.unknown;
    }

    function registerPlayer(address playerAddr) public onlyOwner {
        require(players[playerAddr].isValid == false,"This address has already been registered as a player.");
        player memory p = player(playerAddr,0,0,0,0,address(0),true);
    }

    function checkPlayers(address[] memory playerAddrs) public onlyOwner returns (bool){
        bool res = true;
        for(uint i = 0; i < playerAddrs.length;i++){
            if(players[playerAddrs[i]].isValid == false) {
                res = false;
                break;
            }
        }
        return res;
    }

    function initGame(address[] memory playerAddrs) public onlyOwner{
        require(checkPlayers(playerAddrs) == true,"Player check failed.");
        game memory g = game(nextGameId,0,playerAddrs,playerAddrs,1);
        games[nextGameId] = g;
        nextGameId++;
    }

    function checkGameId(uint gameId) public returns(bool) {
        return (games[gameId].status != 0 && games[gameId].status != 3);
    }

    function getCard(uint cardNum) public returns(uint,uint) {
        // 0-12 54-66 红桃A-K
        // 13-25 67-79 黑桃A-K
        // 26-38 80-92 梅花A-K
        // 39-51 93-105 方块A-K
        // 52-53 105-107 小/大王
        uint color = cardNum % 54 / 13;
        uint num = (cardNum % 54) % 13;
        if(color == 4){
            num += 13;
        }
        return (color,num);
    }

    function checkCardArray(address sender,uint[] memory cardIds) public returns(bool) {
        uint arraySize = cardIds.length;
        for(uint i = 0;i < arraySize;i++){
            if(cardMap[sender][cardIds[i]].owner != sender) return false;
        }
        return true;
    }

    function randomHandCard(address[] memory playerAddrs) public onlyOwner{
        require(deck.length >= 108, "Invalid deck length.");
        uint remaining = 108;
        for(uint i = 0;i < 27;i++){
            for(uint j = 0;j < 4;j++){
                uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp,i,j))) % remaining;
                uint cardNum = deck[randomIndex];
                deck[randomIndex] = deck[remaining - 1];
                remaining--;
                uint c;
                uint n;
                (c,n) = getCard(cardNum);
                card memory tempCard = card(c,n,playerAddrs[j],true);
                cardMap[playerAddrs[j]][i] = tempCard;
            }
        }
    }

    function initRound(uint gameId,address[] memory playerAddrs) public {
        require(games[gameId].status == 0 || games[gameId].status == 3,"This game doesn't exist or is over.");
        round memory r = round(games[gameId].roundId,2,0,cardType.unknown,address(0),false,true);
        gameRound[gameId][r.roundId] = r;
        games[gameId].roundId++;
        randomHandCard(olayerAddrs);
    }

    function checkRoundId(uint gameId,uint roundId) returns(bool) {
        if(checkGameId(gameId) == false) return false;
        return (gameRound[gameId][roundId].isOver == false && gameRound[gameId][roundId].isValid == true);
    }

    function sendCardArray(uint gameId,uint roundId,address sender,cardArray[] memory cardArr) public return(bool){
        require(checkRoundId(gameId,roundId) == true,"Invalid gameId and roundId.");
        
        
        
        
        
        
        
        return true;
    }


}