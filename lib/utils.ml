let log_debug = Printf.eprintf
let sprintf = Printf.sprintf

let string_join c l =
  let open Base in
  l
  |> List.fold ~init:"" ~f:(fun acc el -> sprintf "%s%c%s" acc c el)
  |> fun s -> String.drop_prefix s 1
