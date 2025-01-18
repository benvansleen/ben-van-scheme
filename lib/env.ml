open Base
open Expr
open Utils

type t = data Hashtbl.M(String).t
and key = string
and data = expr

let make ?(default = []) () : t =
  match Hashtbl.of_alist (module String) default with
  | `Ok env -> env
  | `Duplicate_key k ->
     failwith @@ sprintf "Environment contains duplicate key: %s" k

let scoped ~env ~f ~bindings ~(binding_eval : env:t -> 'a -> 'b) =
  let old = Hashtbl.create (module String) in
  let env =
    List.fold bindings ~init:env ~f:(fun env (key, d) ->
                let _ = Hashtbl.add old ~key ~data:(Hashtbl.find env key) in
                let data = binding_eval ~env d in
                Hashtbl.set env ~key ~data;
                env)
  in
  let result = f ~env in
  Hashtbl.iteri old ~f:(fun ~key ~data ->
                  match data with
                  | Some data -> Hashtbl.set env ~key ~data
                  | None -> Hashtbl.remove env key);
  result

let find_exn = Hashtbl.find_exn
let find = Hashtbl.find
let set env ~key ~data = Hashtbl.set env ~key ~data
