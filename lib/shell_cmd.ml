open Utils

let which cmd =
  let cmd = sprintf "which %s" cmd in
  match Stdlib.Sys.command cmd with
  | 0 -> true
  | _ -> false

let exec_with_output cmd args =
  let cmd = string_join ' ' (cmd :: args) in
  log_debug "EVALUATING: %s\n" cmd;
  let ic = Unix.open_process_in cmd in
  let all_input = ref [] in
  try
    while true do
      all_input := Stdlib.input_line ic :: !all_input
    done
  with End_of_file ->
    Stdlib.close_in ic;
    !all_input |> List.rev |> string_join '\n'
