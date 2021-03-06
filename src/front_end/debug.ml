open Printf

let rec indent p k =
  if k>0 then
    fprintf p " %a" indent (k-1)

let debug =
object
  val mutable debug_level = 0
  val mutable blocking_level = 0
  val mutable error_channel = stderr
    
  method set_debug_level x = 
    assert (x>=0); 
    debug_level <- x

  method set_blocking_level x =
    assert (x>=0); 
    blocking_level <- x

  method set_error_channel c =
    error_channel <- c

(* Plus les messages expriment une info détaillée, plus le niveau est haut *)
(* Usage : remplacer eprintf format arg1 ... argN par debug#p k format arg1 ... argN *)
  method p : 'a.int -> ?stops:bool -> ('a, out_channel, unit) format -> 'a =
    fun k ?(stops=false) ->
    assert (k>=0);
    if debug_level >= k then
      begin
        fprintf (error_channel) "[debug]%a" indent k;
        kfprintf (fun p -> 
          fprintf p "\n%!";
          if stops && blocking_level >= k then
            begin
              fprintf (error_channel) ">%!";
              ignore (input_line stdin)
            end)
          (error_channel)
      end
    else
      ifprintf stdout (* Ne fait rien *)
end


(*********)

let stats =
  let init = ["Conflits";"Paris"] in
object (self)
  val data : (string,int) Hashtbl.t = Hashtbl.create 10
  val timers : (string,float) Hashtbl.t = Hashtbl.create 10
  val timers_temp : (string,float) Hashtbl.t = Hashtbl.create 10

  initializer
    List.iter (fun s -> Hashtbl.add data s 0) init
    
  method record s = 
    try 
      let n = Hashtbl.find data s in
      Hashtbl.replace data s (n+1)
    with
      | Not_found -> 
          Hashtbl.add data s 1

  method print p =
    Hashtbl.iter (fun s n -> fprintf p "[stats] %s = %d\n" s n) data;
    fprintf p "\n";
    Hashtbl.iter (fun s t -> fprintf p "[timer] %s : %.5f\n" s t) timers

  method private record_timer s t = 
    try 
      let t0 = Hashtbl.find timers s in
      Hashtbl.replace timers s (t+.t0)
    with
      | Not_found -> 
          Hashtbl.add timers s t
          
  method start_timer s = 
    let start = Unix.times() in 
      Hashtbl.replace timers_temp s Unix.(start.tms_utime +. start.tms_stime) 
      
  method stop_timer s = 
    let stop = Unix.times() in
      try 
        let t = (Hashtbl.find timers_temp s) in
          self#record_timer s Unix.(stop.tms_utime +. stop.tms_stime -. t) 
      with
        | Not_found ->  ()
end












