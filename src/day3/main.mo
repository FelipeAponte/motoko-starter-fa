import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Int "mo:base/Int";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  var messageId : Nat = 0;

  func _hashNat(n : Nat) : Hash.Hash {
    Text.hash(Nat.toText(n));
  };

  let wall = HashMap.HashMap<Nat, Message>(0, Nat.equal, _hashNat);

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let msg : Message = {
      content = c;
      vote = 0;
      creator = caller; 
    };
    
    if(wall.size() == 0){
      messageId := 0;
    } else {
      messageId += 1; 
    };
    
    wall.put(messageId, msg);
    return messageId;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    switch(wall.get(messageId)){
      case(null){return #err("id not found")};
      case(?msg){return #ok(msg)};
    };
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    switch(wall.get(messageId)){
      case(null){return #err("id not found")};
      case(?msg){
        if(msg.creator != caller){
          return #err("you are not the creator of the content");
        };
        let newMsg : Message = {
          content = c;
          vote = msg.vote;
          creator = msg.creator; 
        };
        ignore wall.replace(messageId, newMsg);
        return #ok();
      };
    };
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)){
      case(null){return #err("id not found")};
      case(?msg){
        wall.delete(messageId);
        return #ok();
      };
    };
  };

  // Voting Up
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)){
      case(null){return #err("id not found")};
      case(?msg){
        let newMsg : Message = {
          content = msg.content;
          vote = msg.vote+1;
          creator = msg.creator; 
        };
        ignore wall.replace(messageId, newMsg);
        return #ok();
      };
    };
  };

  // Voting Down
  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)){
      case(null){return #err("id not found")};
      case(?msg){
        let newMsg : Message = {
          content = msg.content;
          vote = msg.vote-1;
          creator = msg.creator; 
        };
        ignore wall.replace(messageId, newMsg);
        return #ok();
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    let array : [Message] = Iter.toArray(wall.vals());
  };

  func compareMessage(m1: Message, m2: Message) : Order.Order {
    switch(Int.compare(m2.vote, m1.vote)){
      case(#less){return #less};
      case(#greater){return #greater};
      case(_){return #equal}
    };
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
    let array : [Message] = Iter.toArray(wall.vals());
    return Array.sort<Message>(array, compareMessage)
  };
};
