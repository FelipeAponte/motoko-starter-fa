import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";

import IC "Ic";
import HTTP "Http";
import Type "Types";
import Iter "mo:base/Iter";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;

  let studentProfileStore = HashMap.HashMap<Principal, StudentProfile>(0, Principal.equal, Principal.hash);

  // STEP 1 - BEGIN
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err("can not add a anonymous profile");
    };

    studentProfileStore.put(caller, profile);
    return #ok();
  };

  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    switch (studentProfileStore.get(p)) {
      case (null) {return #err("profile not found")};
      case (?profile) {
        return #ok(profile);
      };
    };
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (null) {return #err("profile not found")};
      case (_) {
        ignore studentProfileStore.replace(caller, profile);
        return #ok();
      };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (null) {return #err("profile not found")};
      case (_) {
        studentProfileStore.delete(caller);
        return #ok();
      };
    };
  };
  // STEP 1 - END

  // STEP 2 - BEGIN
  type calculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public func test(canisterId : Principal) : async TestResult {
    let calculator : calculatorInterface = actor(Principal.toText(canisterId));

    try {
      let result1 = await calculator.reset();
      if(result1 != 0){
        return #err(#UnexpectedValue("error reset"));
      };
      let result2 = await calculator.add(1);
      if(result2 != 1){
        return #err(#UnexpectedValue("error add"));
      };
      let result3 = await calculator.sub(1);
      if(result3 != 0){
        return #err(#UnexpectedValue("error sud"));
      };
      return #ok();
    } catch (e) {
      return #err(#UnexpectedError("unexpected error"));
    }
  };
  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  func _parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
    let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
    let words = Iter.toArray(Text.split(lines[1], #text(" ")));
    var i = 2;
    let controllers = Buffer.Buffer<Principal>(0);
    while (i < words.size()) {
      controllers.add(Principal.fromText(words[i]));
      i += 1;
    };
    Buffer.toArray<Principal>(controllers);
  };

  public func verifyOwnership(canisterId : Principal, principalId : Principal) : async Bool {
    let managementCanister : IC.ManagementCanisterInterface = actor ("aaaaa-aa");
    try {
      let result = await managementCanister.canister_status({canister_id = canisterId});
      let controllers = result.settings.controllers;
      for (p in controllers.vals()){
        if (p == principalId){
          return true;
        };
      };
      return false;
    } catch (e) {
      let message = Error.message(e);
      let controllers = _parseControllersFromCanisterStatusErrorIfCallerNotController(message);
      for (p in controllers.vals()){
        if (p == principalId){
          return true;
        };
      };
      return false;
    };
   };
  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    let isOwner = await verifyOwnership(canisterId, p);
    if (not(isOwner)) {
      return #err("The caller is not the owner of the canister");
    };

    let result = await test(canisterId);
    switch (result) {
      case (#err(_)) {
        return #err("The canister does not pass the tests");
      };
      case (#ok()) {
        switch (studentProfileStore.get(p)) {
          case (null) {
            return #err("profile not found");
          };
          case (?profile) {
            let newProfile = {
              name = profile.name;
              team = profile.team;
              graduate = true;
            };
            studentProfileStore.put(p, newProfile);
            return #ok();
          };
        }
      }
    }

  };
  // STEP 4 - END

  // // STEP 5 - BEGIN
  // public type HttpRequest = HTTP.HttpRequest;
  // public type HttpResponse = HTTP.HttpResponse;

  // // NOTE: Not possible to develop locally,
  // // as Timer is not running on a local replica
  // public func activateGraduation() : async () {
  //   return ();
  // };

  // public func deactivateGraduation() : async () {
  //   return ();
  // };

  // public query func http_request(request : HttpRequest) : async HttpResponse {
  //   return ({
  //     status_code = 200;
  //     headers = [];
  //     body = Text.encodeUtf8("");
  //     streaming_strategy = null;
  //   });
  // };
  // // STEP 5 - END
};
