open Base
open Ben_van_scheme

let fail name actual expected =
  let err =
    Printf.sprintf "failed test (%s)\n\texpected: %s\n\tactual: %s" name
      expected actual
  in
  Stdlib.print_endline err;
  failwith err

let harness name cmd expected =
  match cmd |> Shell.eval |> List.last with
  | Some s when String.equal s expected -> ()
  | Some s -> fail name s expected
  | _ -> fail name "" expected

let test_addition () =
  let cmd = "\n\n\n\t\t\t\t\t\t+ 1 1\n\n\n\n\n\n\n\n1\n\n\n1 1" in
  harness "addition" cmd "5"

let test_add_float () =
  let cmd = "+ 10. 1" in
  harness "add_float" cmd "11."

let test_sh () =
  let cmd = "echo \"hi\"" in
  harness "sh" cmd "\"hi\""

let test_fact () =
  let cmd =
    "\n\
     (define (fact n)\n\
    \  (let ((decr (lambda (n) (- n 1))))\n\
    \    (if n \n\
    \        (* n (fact (decr n)))\n\
    \        1)))\n\n\
     (fact 5)\n\
     \t"
  in
  harness "factorial" cmd "120"

let () =
  test_addition ();
  test_add_float ();
  test_sh ();
  test_fact ()
