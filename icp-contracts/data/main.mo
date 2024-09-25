import Types "types";
import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";

actor {
    type Entry = Types.Entry;

    var entriesData = TrieMap.TrieMap<Text, Entry>(Text.equal, Text.hash);
    stable var _entries : [(Text, Entry)] = [];

    system func preupgrade() {
        _entries := Iter.toArray(entriesData.entries());
    };

    system func postupgrade() {
        entriesData := TrieMap.fromEntries(_entries.vals(), Text.equal, Text.hash);
        _entries := [];
    };

    public shared func getAllEntries() : async [Entry] {
        return Iter.toArray(entriesData.vals());
    };

    public shared func getEntryById(id : Text) : async ?Entry {
        return entriesData.get(id);
    };

    public shared func insertEntry(entry : Entry) : async () {
        entriesData.put(entry.id, entry);
    };
};
