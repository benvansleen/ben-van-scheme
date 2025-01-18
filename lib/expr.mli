type number = [ `Int of int | `Float of float ]

type expr =
  [ number
  | `String of string
  | `Symbol of symbol
  | `Parenthesized of expr
  | `Op of operation
  | `If of if_
  | `Let of let_
  | `Lambda of lambda
  | `Define of define
  | `List of expr list
  | `Callable of symbol -> expr list -> expr ]

and operation = { f: symbol; args : expr list }
and if_ = { cond : expr; branch_if_true : expr; branch_if_false : expr }
and let_ = { bindings : binding list; body : expr }
and lambda = { args : symbol list; body : expr }
and define = { name : symbol; value : expr }
and binding = symbol * expr
and symbol = string
