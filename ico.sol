pragma solidity ^0.4.24;

contract ERC20Interface{
    
    function totlasupply() public view returns(uint);
    function balanceOf (address tokenOwner) public view returns(uint balance);
    function transfer(address to, uint tokens) public returns(bool success);
    function allowance(address TokenOwner, address spender) public view returns(uint remaining);
    function approve(address spender, uint token) public returns(bool success);
    function transferFrom(address from, address to, uint token) public returns(bool success);
    
    event Transfer(address indexed from, address indexed to,uint tokens);
    event Approval(address indexed tokenOwner,address indexed spender,uint token);
}

contract Crypto is ERC20Interface{
    
    string public name="Ashis";
    string public symbol="AKP";
    uint public decimals=0;
    uint public supply;
    address public founder;
    
    event Transfer(address indexed from, address indexed to,uint tokens);
    
    constructor ()public{
        supply=1000000;
        founder=msg.sender;
        balances[founder]=supply;
    }
    
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) public allowed;
    
    function allowance(address TokenOwner, address spender) public view returns(uint remaining){
        return allowed[TokenOwner][spender];
    }
    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender]>= tokens);
        require(tokens>0);
        
        allowed[msg.sender][spender] = tokens;
       // emit Approval(msg.sender,spender,tokens);
        
        return true;
        
    }
    function transferFrom(address from, address to, uint token) public returns(bool){
        require(allowed[from][to]>= token);
        require(balances[from]>=token);
        
        balances[from]-=token;
        balances[to]+=token;
        
        allowed[from][to]-=token;
        
        return true;
        
    }
    
     function totlasupply() public view returns(uint){
         return supply;
     }
     
     function balanceOf (address tokenOwner) public view returns(uint balance){
         return balances[tokenOwner];
     }
      function transfer(address to, uint tokens) public returns(bool success){
        require(balances[msg.sender]>=tokens && tokens>0); 
        balances[to]+=tokens;
        balances[msg.sender]-=tokens;
        return true;
        emit Transfer(msg.sender,to,tokens);
        
        
      }
}

contract CryptoICO is Crypto{
    
    address public admin;
    address public depositor;
    
    uint tokenPrice= 100000000000000000;
    
    uint public hardCap=3000000000000000000000;
    uint public raisedAmount;
    uint public salesStart=now;
    uint public salesEnd= now + 604800;
    
    uint public coinTradeStart = salesEnd+604800;
    
    uint public maxInvestment = 5000000000000000000;
    uint public minInvestment =  10000000000000000;
    
    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;
    
    modifier onlyAdmin(){
        require(msg.sender==admin);
        _;
    }
    
    constructor(address _depoistor) public{
        depositor=_depoistor;
        admin=msg.sender;
        icoState=State.beforeStart;
    }
    //in case of emergency
    function halt() public onlyAdmin{
        
        icoState=State.halted;
    }
    
    //Start
    
    function unhalt() public onlyAdmin{
        icoState=State.running;
    } 
    
    function ChangeAddress(address newDeposit) public onlyAdmin{
        
        depositor=newDeposit;
    }
    
    function getStatus() public view returns(State){
        
        if(icoState==State.halted)
        {
            return State.halted;
        }
        
        else if(block.timestamp< salesStart)
        {
            return State.beforeStart;
        }
        else if(block.timestamp>=salesStart && block.timestamp<=salesEnd)
        {
            return State.running;
        }
        else  return State.afterEnd;
    }
    event Invest(address investor,uint value,uint tokens);
    function invest() payable public returns(bool){
        
        //invest only in runnung
        icoState=getStatus();
        require(icoState == State.running);
        
        require(msg.value>=minInvestment && msg.value<=maxInvestment);
        uint tokens = msg.value/tokenPrice;
        require(raisedAmount+msg.value<=hardCap);
        raisedAmount+=msg.value;
        
        balances[msg.sender]+=tokens;
        balances[founder]-=tokens;
        
        depositor.transfer(msg.value);
        return true;
        emit Invest(msg.sender,msg.value,tokens);
        
        
    }
    //fallback function in case someone sends ether directly to the contract
    function () payable public{
        invest();
    }
    function transfer(address to,uint value) public returns(bool){
        require(block.timestamp>coinTradeStart);
        super.transfer(to,value);
        
    }
    function transferFrom(address _from,address _to,uint _value) public returns(bool){
        require(block.timestamp>coinTradeStart);
        super.transferFrom(_from,_to,_value);
    }
    function burn() public returns(bool){
        icoState=getStatus();
        require(icoState==State.afterEnd);
        balances[founder]=0;
    }
}
