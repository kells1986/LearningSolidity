// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RandomPayout {
 
    //Store data about who's playing
    struct Participant {
        address payable wallet;
        uint timeJoined;
        bool paymentTaken;
        uint paymentAmount;
    }
 
    //Store data about the final result
    struct Result {
        Participant winner;
        uint prize;
        uint timestamp;
    }
 
    //emit this when someone new joins
    event BuyIn(
        Participant player);
        
    //emit this when the game finishes
    event GameCompleted(
        Result result);
        
 
    //me
    address payable public chairperson;
    
    //set at consturction time
    uint public maxParticipants;
    //set at consturction time
    uint public costPerParticipant;

    //Fraction of prize pool paid
    uint constant percentPayout = 95;
    
    //Track prizePool value
    uint public prizePool = 0;
    
    uint public numberOfParticipants = 0;
    //Track participants
    Participant[] private participants;
    
    
    bool public gameComplete = false;
    
    
    modifier gameCompleted(){
        gameComplete;
        _;
    }
    
    modifier onlyChairPerson(){
        msg.sender == chairperson;
        _;
    }
    
    modifier onlyPlayerOrChairman() {
        bool isPlayer = false;
        for(uint index=0; index < participants.length; index++){
            if (participants[index].wallet == msg.sender){
                isPlayer = true;
                break;
            }
        }
        isPlayer || msg.sender == chairperson;
        _;
    }
    
    
    modifier gameNotFull(){
        numberOfParticipants < maxParticipants;
        _;
    }
    
    modifier gameNotCompleted() {
        !gameComplete;
        _;
    }
    
    function toPayable(address input) private returns(address payable) {
        address payable sender = payable(input);
        return sender;
    }
 
    constructor(uint _maxParticipants, uint _costPerParticipant){
        chairperson = toPayable(msg.sender);
        maxParticipants = _maxParticipants;
        costPerParticipant = _costPerParticipant;
    }   
    
    
    function optIn () payable external gameNotFull gameNotCompleted returns(bool) {
        if (msg.value >= costPerParticipant) {
            
            chairperson.transfer(costPerParticipant);
            Participant memory player;
            player = Participant(toPayable(msg.sender), block.timestamp, true, costPerParticipant);
            participants.push(player);
            numberOfParticipants += 1;
            prizePool += costPerParticipant;
            emit BuyIn(player);
            return true;
        }
        else{
            return false;
        }
        
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(block.timestamp * block.difficulty)%251);
    }
    
    function playGame() payable public onlyPlayerOrChairman gameNotCompleted {
        uint8 winner_index = random() % uint8(participants.length);
        Participant memory winner = participants[winner_index];
        uint prize = (95 * prizePool) / 100;
        winner.wallet.transfer(prize);
        
        Result memory result = Result(winner, prize, block.timestamp);
        emit GameCompleted(result);
        gameComplete = true;
        finalize();
        
    }
    
    function finalize() public gameCompleted onlyChairPerson{
        selfdestruct(chairperson);
    }

}