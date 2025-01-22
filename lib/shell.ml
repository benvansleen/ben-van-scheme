open Base

let interactive () =
  let i = ref 1 in
  while true do
    Stdlib.print_string "> ";
    let input = Parser.parse @@ Stdlib.read_line () in
    let result = List.map input ~f:Evaluate.eval in
    List.iter (List.zip_exn input result) ~f:(fun (input, output) ->
        Stdlib.Printf.printf "%d: %s = %s\n" !i (Pp.string_of_expr input)
          output);
    i := !i + 1
  done

let eval s = s |> Parser.parse |> List.map ~f:Evaluate.eval

let read_file_to_string filename =
  let open Stdlib in
  let ic = open_in_bin filename in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let run_file filename =
  filename
  |> read_file_to_string
  |> eval
  |> List.iter ~f:Stdlib.print_endline
