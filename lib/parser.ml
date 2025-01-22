open Base
open Angstrom
open Expr
open Utils

let whitespace = take_while Char.is_whitespace

let is_digit = function
  | '0' .. '9' -> true
  | _ -> false

let digits = take_while1 is_digit
let whitespace_around p = whitespace *> p <* whitespace

let is_symbol_ch = function
  | '+' | '-' | '*' | '/' | '^' -> true
  | ch when Char.is_alpha ch -> true
  | _ -> false

let symbol = take_while1 is_symbol_ch
let keyword kw = whitespace_around @@ string kw

let whole_number =
  let+ sign = char '-' |> option '+'
  and+ whole = digits in
  sprintf "%c%s" sign whole

let float =
  let+ whole = whole_number
  and+ _decimal_point = char '.'
  and+ fraction = option "0" digits in
  let f = sprintf "%s.%s" whole fraction |> Float.of_string in
  `Float f

and integer =
  let+ whole = whole_number in
  let i = Int.of_string whole in
  `Int i

let number = choice [ float; integer ]

let wrapped_by ch_open p ch_close =
  let+ _opening = char ch_open
  and+ expr = p
  and+ _closing = char ch_close in
  expr

let wrapped_by_paren expr = wrapped_by '(' expr ')'

let parenthesized expr =
  let+ expr = wrapped_by_paren expr in
  `Parenthesized expr

let op expr =
  let+ f = whitespace_around symbol
  and+ args = many expr in
  `Op { f; args }

let if_ expr =
  let+ _if = keyword "if"
  and+ cond = expr
  and+ branch_if_true = expr
  and+ branch_if_false = expr in
  `If { cond; branch_if_true; branch_if_false }

let bindings expr =
  let binding expr =
    let binding =
      let+ symbol = symbol
      and+ _sep = whitespace
      and+ expr = expr in
      (symbol, expr)
    in
    let+ binding = wrapped_by_paren binding in
    binding
  in
  let+ bindings =
    wrapped_by_paren @@ many1 @@ whitespace_around @@ binding expr
  in
  bindings

let let_ expr =
  let+ _let = keyword "let"
  and+ bindings = bindings expr
  and+ body = expr in
  `Let { bindings; body }

let argument_list =
  let+ args = wrapped_by_paren @@ many @@ whitespace_around symbol in
  args

let lambda expr =
  let+ _lambda = keyword "lambda"
  and+ args = argument_list
  and+ body = expr in
  `Lambda { args; body }

let define expr =
  let define_expr expr =
    let+ name = whitespace_around symbol
    and+ value = expr in
    `Define { name; value }
  in
  let define_fn expr =
    let+ args = argument_list
    and+ body = expr in
    match args with
    | [] -> failwith "fn must have a name"
    | name :: args -> `Define { name; value = `Lambda { args; body } }
  in
  let+ _define = keyword "define"
  and+ define = choice [ define_fn expr; define_expr expr ] in
  define

let string_ =
  let string_char = take_till (fun ch -> Char.equal ch '"') in
  let+ chars = wrapped_by '"' string_char '"' in
  `String chars

let list expr =
  let elements = sep_by whitespace expr in
  let+ list = wrapped_by '[' elements ']' in
  `List list

let symbol =
  let+ s = symbol in
  `Symbol s

let compound expr =
  [ define; lambda; let_; if_; op ]
  |> List.map ~f:(fun p -> p expr)
  |> choice

let terminal expr = choice [ list expr; symbol; string_; number ]

let expr =
  fix
  @@ fun expr ->
  whitespace_around (parenthesized @@ compound expr <|> terminal expr)

let root_expr =
  choice
    [ compound expr; expr ]
    ~failure_msg:"Failed parsing root expression"

let parse s =
  let parser = many root_expr in
  match parse_string ~consume:All parser s with
  | Error s -> Stdlib.failwith s
  | Ok s -> s
