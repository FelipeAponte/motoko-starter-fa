import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
// import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  public type Account = Account.Account;

  let ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  let airdropCanisterId = "rww3b-zqaaa-aaaam-abioa-cai";

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var total : Nat = 0;
    for (v in ledger.vals()){
      total += v;
    };
    total;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    switch (ledger.get(account)) {
      case (null) {return 0};
      case (?val) {return val};
    }
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    switch (ledger.get(from)) {
      case (null) {return #err("you do not have an account")};
      case (?valFrom) {
        if (amount > valFrom) {
          return #err("you do not have enough money");
        };
        switch (ledger.get(to)) {
          case (null) {return #err("the recipient does not exist")};
          case (?valTo) {
            ignore ledger.replace(from, valFrom-amount);
            ignore ledger.replace(to, valTo+amount);
            return #ok();
          };
        };
      };
    }
  };

  // Airdrop 100 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    let bootCall = actor (airdropCanisterId) : actor {
      getAllStudentsPrincipal : shared () -> async [Principal];
    };

    let principalList = await bootCall.getAllStudentsPrincipal();

    for (p in principalList.vals()) {
      let studentAcount : Account = {
        owner = p;
        subaccount = null;
      };
      ledger.put(studentAcount, 100);
    }; 
    
    return #ok();
  };
};
