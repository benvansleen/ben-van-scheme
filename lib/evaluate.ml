open Base
open Shell_cmd
open Expr
open Utils

let shell_cmd cmd ~env =
  match which cmd with
  | true ->
     log_debug "Storing shell cmd: %s\n" cmd;
     let call =
       `Callable
        (fun _s args ->
          let args = List.map args ~f:Pp.string_of_expr in
          `String (exec_with_output cmd args))
     in
     Env.set env ~key:cmd ~data:call;
     cmd
  | false -> failwith @@ sprintf "No command found in PATH: %s" cmd

let rec eval ~env = function
  | (#number | `String _ | `Callable _) as expr -> expr
  | `List exprs -> eval_list exprs ~env
  | `Symbol s -> eval_symbol s ~env
  | `Parenthesized expr -> eval_parenthesized expr ~env
  | `Op op -> eval_op op ~env
  | `If if_ -> eval_if if_ ~env
  | `Let let_ -> eval_let let_ ~env
  | `Lambda lambda -> eval_lambda lambda ~env
  | `Define define -> eval_define define ~env

and eval_list exprs ~env =
  let exprs = List.map exprs ~f:(eval ~env) in
  `List exprs

and eval_symbol s ~env =
  match Env.find env s with
  | Some expr -> expr
  | None -> `Symbol s

and eval_parenthesized expr ~env =
  match expr with
  | `Symbol s -> eval_op { f = s; args = [] } ~env
  | Some expr -> eval_expr expr f args ~env

and to_bool = function
  | `Int n -> n <> 0
  | `String s -> not @@ String.is_empty s
  | `List l -> not @@ List.is_empty l
  | _ -> false

and eval_if { cond; branch_if_true; branch_if_false } ~env =
  if to_bool @@ eval cond ~env then eval branch_if_true ~env
  else eval branch_if_false ~env

and eval_let { bindings; body } ~env =
  Env.scoped ~env ~bindings ~binding_eval:eval ~f:(eval body)

and eval_lambda { args; body } ~env =
  let inspect_call f args =
    log_debug "Calling: %s\n" f;
    List.iter args ~f:(fun (k, v) ->
                log_debug "(%s %s)\n" k (Pp.string_of_expr v))
  in
  let rec call self params =
    let bindings = (self, `Callable call) :: List.zip_exn args params in
    inspect_call self bindings;
    Env.scoped ~env ~bindings ~binding_eval:eval ~f:(eval body)
  in
  `Callable call

and eval_define { name; value } ~env =
  Env.set env ~key:name ~data:(eval value ~env);
  `Symbol name

let default_env =
  let lift f = `Callable (fun _ -> f) in
  let open Math in
  Env.make ()
           ~default:
           [
             ("+", lift add);
             ("-", lift subtract);
             ("*", lift multiply);
             ("/", lift divide);
             ("^", lift power);
           ]

let eval expr = expr |> eval ~env:default_env |> Pp.string_of_expr
