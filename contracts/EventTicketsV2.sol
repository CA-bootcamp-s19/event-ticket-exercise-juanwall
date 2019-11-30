pragma solidity ^0.5.0;

  /*
      The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
    */
contract EventTicketsV2 {

  /*
    Define an public owner variable. Set it to the creator of the contract when it is initialized.
  */
  address payable public owner;

  uint PRICE_TICKET = 100 wei;

  /*
    Create a variable to keep track of the event ID numbers.
  */
  uint public idGenerator;

  /*
    Define an Event struct, similar to the V1 of this contract.
    The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
    Choose the appropriate variable type for each field.
    The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
  */
  struct Event {
    string description;
    string website;
    uint totalTickets;
    uint sales;
    mapping (address => uint) buyers;
    bool isOpen;
  }

  /*
    Create a mapping to keep track of the events.
    The mapping key is an integer, the value is an Event struct.
    Call the mapping "events".
  */
  mapping (uint => Event) events;

  event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
  event LogBuyTickets(address buyer, uint eventId, uint numTickets);
  event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
  event LogEndSale(address owner, uint balance, uint eventId);

  /*
      Create a modifier that throws an error if the msg.sender is not the owner.
  */
  modifier verifyOwner() {
    require(msg.sender == owner, 'You must be the contract owner');

    _;
  }

  // modifier eventExists(uint eventId) {
  //   require(events[eventId] != 0, 'Event with eventId does not exist');

  //   _;
  // }

   modifier isOpenMod(Event memory myEvent) {
    require(myEvent.isOpen, 'The event is not open');

    _;
  }

  modifier paidEnough(uint numTickets) {
    require(msg.value >= numTickets * PRICE_TICKET, 'You did not pay enough');

    _;
  }

  modifier ticketsAvailable(Event memory myEvent, uint numTickets) {
    require(myEvent.totalTickets - myEvent.sales >= numTickets, 'There are not enough tickets available');

    _;
  }

  modifier checkValue(uint numTickets) {
    _;

    uint amountToRefund = msg.value - (PRICE_TICKET * numTickets);

    msg.sender.transfer(amountToRefund);
  }

  modifier hasPurchased(Event storage myEvent) {
    require(myEvent.buyers[msg.sender] > 0, 'You have not bought any tickets');

    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  /*
    Define a function called addEvent().
    This function takes 3 parameters, an event description, a URL, and a number of tickets.
    Only the contract owner should be able to call this function.
    In the function:
      - Set the description, URL and ticket number in a new event.
      - set the event to open
      - set an event ID
      - increment the ID
      - emit the appropriate event
      - return the event's ID
  */
  function addEvent(string memory _description, string memory _website, uint _totalTickets) public verifyOwner() returns(uint eventId) {
    eventId = idGenerator;

    events[eventId] = Event({
      description: _description,
      website: _website,
      totalTickets: _totalTickets,
      sales: 0,
      isOpen: true
    });

    idGenerator += 1;

    emit LogEventAdded(_description, _website, _totalTickets, eventId);

    return eventId;
  }

  /*
    Define a function called readEvent().
    This function takes one parameter, the event ID.
    The function returns information about the event this order:
      1. description
      2. URL
      3. tickets available
      4. sales
      5. isOpen
  */
  function readEvent(uint eventId)
    public
    view
    // eventExists(eventId)
    returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
  {
    Event storage myEvent = events[eventId];

    return (myEvent.description, myEvent.website, myEvent.totalTickets, myEvent.sales, myEvent.isOpen);
  }

  /*
    Define a function called buyTickets().
    This function allows users to buy tickets for a specific event.
    This function takes 2 parameters, an event ID and a number of tickets.
    The function checks:
      - that the event sales are open
      - that the transaction value is sufficient to purchase the number of tickets
      - that there are enough tickets available to complete the purchase
    The function:
      - increments the purchasers ticket count
      - increments the ticket sale count
      - refunds any surplus value sent
      - emits the appropriate event
  */
  function buyTickets(uint eventId, uint numTickets)
    public
    payable
    // eventExists(eventId)
    isOpenMod(events[eventId])
    paidEnough(numTickets)
    ticketsAvailable(events[eventId], numTickets)
    checkValue(numTickets)
  {
    events[eventId].buyers[msg.sender] += numTickets;

    events[eventId].sales += numTickets;

    emit LogBuyTickets(msg.sender, eventId, numTickets);
  }

  /*
    Define a function called getRefund().
    This function allows users to request a refund for a specific event.
    This function takes one parameter, the event ID.
    TODO:
      - check that a user has purchased tickets for the event
      - remove refunded tickets from the sold count
      - send appropriate value to the refund requester
      - emit the appropriate event
  */
  function getRefund(uint eventId) public hasPurchased(events[eventId]) {
    Event storage myEvent = events[eventId];

    uint numTickets = myEvent.buyers[msg.sender];

    myEvent.sales -= numTickets;

    msg.sender.transfer(PRICE_TICKET * numTickets);

    emit LogGetRefund(msg.sender, eventId, numTickets);
  }

  /*
    Define a function called getBuyerNumberTickets()
    This function takes one parameter, an event ID
    This function returns a uint, the number of tickets that the msg.sender has purchased.
  */
  function getBuyerNumberTickets(uint eventId) public view returns(uint numTickets) {
    return events[eventId].buyers[msg.sender];
  }

  /*
    Define a function called endSale()
    This function takes one parameter, the event ID
    Only the contract owner can call this function
    TODO:
      - close event sales
      - transfer the balance from those event sales to the contract owner
      - emit the appropriate event
  */
  function endSale(uint eventId) public verifyOwner() {
    Event storage myEvent = events[eventId];

    myEvent.isOpen = false;

    msg.sender.transfer(address(this).balance);

    emit LogEndSale(owner, myEvent.sales * PRICE_TICKET, eventId);
  }
}
