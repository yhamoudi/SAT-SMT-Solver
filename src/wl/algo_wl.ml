open Formule
open Formule_wl
open Clause
open Debug
open Answer

exception Wl_fail


(***************************************************)


let next_pari formule = (* Some v si on peut faire le prochain pari sur v, None si tout a été parié *)
  let n=formule#get_nb_vars in
  let rec parcours_paris = function
    | 0 -> None
    | m -> 
        if (formule#get_pari m != None) then 
          parcours_paris (m-1) 
        else 
          Some m in
  parcours_paris n

(***************************************************)

(* constraint_propagation reçoit un ordre d'assignation de b sur la variable var : 
      elle doit faire cette assignation et toutes celles qui en découlent, ssi pas de conflits créés
      si conflits, aucune assignation ne doit être faite + toutes les variables figurant dans l doivent être dé-assignées
      si réussit : renvoie la liste des assignations effectuées
*)
(* l : liste des assignations effectuées depuis le dernier pari, inclu *)
let rec constraint_propagation (formule : Formule_wl.formule_wl) var b l =
  debug 5 "Propagation : setting %d to %B" var b;
  formule#set_val b var; (* on pari b sur var *)
  debug 3 "WL : abandon watched literal %d %B required" var (not b); 
  (formule#get_wl (not b,var))#fold  (* on parcourt  les clauses où var est surveillée et est devenue fausse, ie là où il faut surveiller un nouveau littéral *) 
    (fun c l_next -> match (formule#update_clause c (not b,var)) with
      | WL_Conflit -> 
         record_stat "Conflits";
         debug 2 ~stops:true "WL : Conflict : clause %d false " c#get_id;
         debug 4 "Propagation : cannot leave wl %B %d in clause %d" (not b) var c#get_id; 
         formule#reset_val var;
         List.iter (fun v -> formule#get_paris#remove v) l_next;
         raise Wl_fail
      | WL_New l -> 
          debug 4 "Propagation : watched literal has moved from %B %d to %B %d in clause %d" (not b) var (fst l) (snd l) c#get_id ; 
          l_next
      | WL_Assign (b_next,v_next) -> 
          debug 4 "Propagation : setting %d to %B in clause %d is necessary (leaving %B %d impossible)" v_next b_next c#get_id (not b) var; 
          constraint_propagation formule v_next b_next l_next
      | WL_Nothing -> 
          debug 4 "Propagation : clause %d satisfied (leaving wl %B %d unnecessary)" c#get_id (not b) var; 
          l_next
    ) (var::l)


(*************)


(* Algo WL *)
let algo n cnf =
  let formule = new formule_wl in


  let rec aux()= (* aux fait un pari et essaye de le prolonger le plus loin possible *)
    match next_pari formule with
      | None -> 
          debug 1 "Done\n";
          true (* plus rien à parier = c'est gagné *)
      | Some var ->  
          try 
            record_stat "Paris";
            debug 2 "WL : trying with %d true" var ;
            debug 2 "WL : starting propagation";
            let l = (constraint_propagation formule var true []) in (* lève une exception si conflit créé, sinon renvoie liste des vars assignées *)
              if aux () then (* on réussit à poursuivre l'assignation jusqu'au bout *)
                begin
                  true (* c'est gagné *)
                end
              else (* pb plus loin dans le backtracking, il faut tout annuler pour parier sur faux *)
                begin
                  List.iter (
                    fun v -> 
                      formule#reset_val v
                  ) l; (* on annule les assignations *)
                  raise Wl_fail
                end
          with
            | Wl_fail ->   
                try 
                  debug 2 "WL : trying with %d false" var ;
                  debug 2 "WL : starting propagation";
                  let l = constraint_propagation formule var false [] in (* on a encore une chance en pariant faux *)
                  if aux () then (* on réussit à poursuivre l'assignation jusqu'au bout *)
                    begin
                     true (* c'est gagné *)
                     end
                  else
                    begin
                      debug 2 "WL : backtracking on var %d" var;
                      List.iter (
                        fun var -> 
                          formule#reset_val var
                      ) l; (* sinon il faut backtracker sur le pari précédent *)
                      false
                    end   
                with
                  | Wl_fail ->
                      begin
                        debug 2 "WL : backtracking on var %d" var; 
                        false
                      end
  in

  try
    formule#init n cnf; (* on a prétraité, peut être des clauses vides créées >> détectées ligne en dessous *)
    formule#check_empty_clause; (* détection de clauses vides *)
    formule#init_wl; (* Les jumelles sont initialisées *)
    (* à partir de maintenant : pas de clauses vides, singletons ou tautologies. Toutes les assignations nécessaires ont été faites. Les variables assignées n'apparaissent plus dans la formule *)
    if aux () then 
      Solvable formule#get_paris
    else 
      Unsolvable
  with
    | Clause_vide -> Unsolvable (* Clause vide dès le début *)





