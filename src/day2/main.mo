import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Text "mo:base/Text";

import Type "Types";

actor class Homework() {
  type Homework = Type.Homework;

  // Define variable homeworkDiary
  let homeworkDiary = Buffer.Buffer<Homework>(0);

  // Add a new homework task
  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    homeworkDiary.size() -1;
  };

  // Get a specific homework task by id
  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    if (id >= homeworkDiary.size()) {
      return #err("homeworkId not found");
    };

    return #ok(homeworkDiary.get(id));
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    if (id >= homeworkDiary.size()) {
      return #err("homeworkId not found");
    };

    homeworkDiary.put(id, homework);
    return #ok();
  };

  // Mark a homework task as completed
  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    if (id >= homeworkDiary.size()) {
      return #err("homeworkId not found");
    };

    let hw : Homework = homeworkDiary.get(id);

    let complete : Homework = {
      title = hw.title;
      description = hw.description;
      dueDate = hw.dueDate;
      completed = true;
    };

    homeworkDiary.put(id, complete);
    return #ok();
  };

  // Delete a homework task by id
  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    if (id >= homeworkDiary.size()) {
      return #err("homeworkId not found");
    };

    var hw = homeworkDiary.remove(id);
    return #ok();
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    Buffer.toArray(homeworkDiary);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    let hwBuf = Buffer.Buffer<Homework>(0);

    for (hw in homeworkDiary.vals()) {
      if (hw.completed == false) {
        hwBuf.add(hw);
      };
    };

    Buffer.toArray(hwBuf);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    let hwBuf = Buffer.Buffer<Homework>(0);

    for (hw in homeworkDiary.vals()) {
      if (Text.contains(hw.description, #text searchTerm)) {
        hwBuf.add(hw);
      };
    };

    Buffer.toArray(hwBuf);
  };
};
