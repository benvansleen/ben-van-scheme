type t
and key = string
and data = Expr.expr

val make : ?default:(key * data) list -> unit -> t

val scoped :
  env:t ->
  f:(env:t -> 'b) ->
  bindings:(key * 'a) list ->
  binding_eval:(env:t -> 'a -> data) ->
  'b

val find_exn : t -> key -> data
val find : t -> key -> data option
val set : t -> key:key -> data:data -> unit
