open Base
open Expr
open Utils

let rec string_of_expr = function
  | #number as n -> string_of_number n
  | `Parenthesized expr -> string_of_expr expr
  | `String s -> sprintf "\"%s\"" s
  | `Symbol s -> s
  | `Op op -> string_of_op op
  | `If if_ -> string_of_if if_
  | `Let let_ -> string_of_let let_
  | `Lambda lambda -> string_of_lambda lambda
  | `Define define -> string_of_define define
  | `List exprs -> string_of_list exprs
  | `Callable _ -> "<lambda>"

and string_of_number = function
  | `Int i -> Int.to_string i
  | `Float f -> Float.to_string f

and string_of_op { f; args } =
  args |> List.map ~f:string_of_expr |> string_join ' ' |> sprintf "(%s %s)" f

and string_of_if { cond; branch_if_true; branch_if_false } =
  let cond, branch_if_true, branch_if_false =
    ( string_of_expr cond,
      string_of_expr branch_if_true,
      string_of_expr branch_if_false )
  in
  sprintf "(if %s %s %s)" cond branch_if_true branch_if_false

and string_of_let { bindings; body } =
  let bindings, body = (string_of_bindings bindings, string_of_expr body) in
  sprintf "(let (%s) %s)" bindings body

and string_of_lambda { args; body } =
  let args, body = (string_join ' ' args, string_of_expr body) in
  sprintf "(lambda (%s) %s)" args body

and string_of_define { name; value } =
  let value = string_of_expr value in
  sprintf "(define %s %s)" name value

and string_of_list exprs =
  exprs |> List.map ~f:string_of_expr |> string_join ' ' |> sprintf "(%s)"

and string_of_bindings bindings =
  bindings |> List.map ~f:string_of_binding |> string_join ' ' |> sprintf "[ %s ]"
  
and string_of_binding (k, v) = sprintf "(%s %s)" k (string_of_expr v)
