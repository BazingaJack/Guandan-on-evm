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
        bool status;
    }

    struct game {
        uint gameId;
        uint round;
        uint level;//级牌
        address[] playerAddrs;
        uint currentNum;
        cardType currentType;
        uint currentCardLevel;
    }

    mapping(address => mapping(uint => card)) cardMap;
    mapping(address => player) players;
    mapping(uint => game) games;

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
        game memory g = game(nextGameId,0,2,playerAddrs,0,cardType.init,0);
        games[nextGameId] = g;
        nextGameId++;
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
                card memory tempCard = card(c,n,true);
                cardMap[playerAddrs[j]][i] = tempCard;
            }
        }
    }

    function start(address[] memory playerAddrs) public {
        initGame(playerAddrs);
        randomHandCard(playerAddrs);

    }

}