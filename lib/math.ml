open Expr

let rec add_nums fst snd =
  match (fst, snd) with
  | `Int f, `Int s -> `Int (f + s)
  | `Float f, `Float s -> `Float (f +. s)
  | `Int f, `Float s -> `Float (Float.of_int f +. s)
  | f, s -> add_nums s f

let map ~f l = `List Base.(List.map l ~f)

let rec add args =
  match args with
  | [] -> `Int 0
  | [ (#number as e) ] | [ (`String _ as e) ] -> e
  | [ f; s ] -> (
    match (f, s) with
    | (#number as f), (#number as s) -> add_nums f s
    | `String f, `String s -> `String (f ^ s)
    | (#number as n), `List l -> map ~f:(add_nums n) l
    | _ ->
       failwith "Addition only defined for Numbers")
  | fst :: snd :: tl -> add (add [ fst; snd ] :: tl)
  | [ _ ] -> failwith "Addition only defined for 2 or more arguments"

and negate = function
  | `Int i -> `Int (-i)
  | `Float f -> `Float (-.f)

and subtract = function
  | [] -> `Int 0
  | [ (#number as n) ] -> negate n
  | [ _ ] -> failwith "Subtraction only defined for 1 or more Numbers"
  | [ (#number as f); (#number as s) ] -> add_nums f (negate s)
  | fst :: snd :: tl -> subtract (subtract [ fst; snd ] :: tl)

and multiply = function
  | [] -> `Int 1
  | [ (#number as n) ] -> n
  | [ _ ] -> failwith "Multiplication only defined for 1 or more Numbers"
  | [ (#number as f); (#number as s) ] -> (
    match (f, s) with
    | `Int f, `Int s -> `Int (f * s)
    | `Float f, `Float s -> `Float (f *. s)
    | `Int f, `Float s -> `Float (Float.of_int f *. s)
    | f, s -> multiply [ s; f ])
| fst :: snd :: tl -> multiply (multiply [ fst; snd ] :: tl)

and divide = function
  | [] | [ _ ] -> failwith "Division only defined for 2 or more Numbers"
  | [ (#number as f); (#number as s) ] -> (
    match (f, s) with
    | `Int f, `Int s -> `Int (f / s)
    | `Float f, `Float s -> `Float (f /. s)
    | `Int f, `Float s -> `Float (Float.of_int f /. s)
    | `Float f, `Int s -> `Float (f /. Float.of_int s))
  | fst :: snd :: tl -> divide (divide [ fst; snd ] :: tl)

and power = function
  | [] | [ _ ] -> failwith "Power only defined for 2 or more Numbers"
  | [ #number; `Int exponent ] when exponent = 0 -> `Int 1
  | [ `Int base; `Int exponent ] when exponent > 0 -> (
    match power [ `Int base; `Int (exponent - 1) ] with
    | `Int i -> `Int (base * i)
    | `Float i -> `Float (Float.of_int base *. i)
    | _ -> failwith "Exponentiation only defined for positive integers")
  | fst :: snd :: tl -> power (power [ fst; snd ] :: tl)
