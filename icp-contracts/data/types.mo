module {
  public type Entry = {
    consumptionPower : Nat;
    updatedTime : Text;
    plantName : Text;
    productionPower : Nat;
    gridPower : Nat;
    timeZone : Text;
  };
  public type Self = actor {
    getAllEntries : shared query () -> async [Entry];
    getEntryById : shared query Nat -> async ?Entry;
    inserEntryt : shared Entry -> async ();
  }
}