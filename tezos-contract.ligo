type action is
    | SendRequest of (address)
    | GetResult of (nat * nat)

type storage is record [
    data: nat * nat;
    creator: address;
    blocked: bool
]

function sendRequest (const dest : address; const storage : storage) : list (operation) * storage is
  block {
    if storage.blocked = True then failwith ("Error forbidden");
    else skip;
    if Tezos.sender =/= storage.creator then failwith ("Error creator");
    else skip; 
    const res : contract(nat * nat) = case (Tezos.get_entrypoint_opt("%getResult", Tezos.self_address) : option(contract(nat * nat))) of 
            | Some (c) -> c
            | None -> (failwith ("Error result"): contract(nat * nat))
    end;
    const ext : contract (contract(nat * nat)) = 
    case (Tezos.get_entrypoint_opt ("%get_info", dest) : option (contract (contract(nat * nat)))) of
            | Some (c) -> c
            | None -> (failwith ("Error result"): contract(contract(nat * nat)))
    end;
    const op : operation = Tezos.transaction (res, 0tez, ext);
    const operations : list (operation) = list [op]
} with (operations, storage)

function getResult (const p: nat * nat; var storage : storage) : list (operation) * storage is
    block {
        storage.data := p;
        storage.blocked := True;
        if (p.1 mod 2n) = 0n then storage.data.1 := 33n;
        else skip
    } with ((nil: list(operation)), storage)

function main (const action : action ; var storage : storage) : list (operation) * storage is
    block { 
        skip 
    } with case action of
        | SendRequest(p) -> sendRequest(p, storage)
        | GetResult(p) -> getResult(p, storage)
    end;
