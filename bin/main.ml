let () =
  match Sys.argv with
  | [| _ |] -> Shell.interactive ()
  | [| _; f |] -> Shell.run_file f
  | _ -> failwith "unknown cli args"
