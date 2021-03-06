(* :Title: 	NCSimplify1Rational // Mathematica 1.2 and 2.0 *)

(* :Authors: 	Bill Helton (helton)
		Lois Yu (lyu) 
		David Hurst (dhurst)
*)

(* :Context: 	NCSimplify1Rational` *)

(* :Summary: 	Simplifies noncommutative expressions in one or two variables 
		and certain functions of their inverses. 

		NCSimplify1Rational[ expr ] simplifies noncommutative 
		polynomials in x & y, inv[x] & inv[x], inv[1-xy] by 
		repeatedly applying a set of reduction rules to the 
		polynomial until it stops changing.

		NCSimplify1RationalSinglePass[ expr ] simplifies 
		noncommutative polynomials in  x & y, inv[x] & inv[y], 
		inv[1-xy] by applying a set of reduction rules to the 
		polynomial for one single application of each rule.

*)

(* :Alias: 	NCS1R::= NCSimplify1Rational
		NCS1RSP::= NCSimplify1RationalSinglePass
*)

(* :Warnings: 	Although This program can handle explicit numeric scalar 
		multipliers, symbolic commutative multipliers must be 
		appropriately typed as commutative.  
		See SetCommutative and CommutativeQ.
*)

(* :History: 
   :7/3/91      Rewrote NCRS. (lyu)
   :7/31/91 	Added rhs's in FullForm. (dhurst)
   :7/20/92     Reformated comments, supplied missing blank in the
  		2nd lhs of rule 2, changed < to <= 
		in the For loop. (dhurst)
   :8/1/97      Replaced the local variable K with LLLLL.  (rowell)
*)

BeginPackage[ "NCSimplify1Rational`", 
              "NCSubstitute`",
              "NonCommutativeMultiply`" ]

NCSimplify1Rational::usage =
     "NCSimplify1Rational[ expr ] simplifies noncommutative expressions in\n
     x, x & y, inv[x], inv[x] & inv[y], inv[1-x], inv[1-x] & inv[1-y],\n
     inv[1-xy] by repeatedly applying a set of reduction rules. ";

NCSimplify1RationalSinglePass::usage =
     "NCSimplify1RationalSinglePass[ expr ] simplifies noncommutative \n 
     expressions in x, x & y, inv[x], inv[x] & inv[y], inv[1-x], inv[1-x]\n
     & inv[1-y], inv[1-xy] by applying a set of reduction rules for one \n
     single pass.";

(* :Definitions:
NCS1Rdefinitions:=Message[NCS1R::definitions];
NCS1Rrule:=Information[ NCSimplify1Rational`Private`rule ];
NCS1Rrule1:=NCSimplify1Rational`Private`rule[1];
NCS1Rrule2:=NCSimplify1Rational`Private`rule[2];
NCS1Rrule3:=NCSimplify1Rational`Private`rule[3];
NCS1Rrule4:=NCSimplify1Rational`Private`rule[4];
NCS1Rrule5:=NCSimplify1Rational`Private`rule[5];
NCS1Rrule6:=NCSimplify1Rational`Private`rule[6];
*)

Begin[ "`Private`" ]

  NCSimplify1Rational[expr1_] := 
       FixedPoint[ NCSimplify1RationalSinglePass, expr1 ];

  NCSimplify1RationalSinglePass[ input_Symbol ] :=
       Return[input];

  NCSimplify1RationalSinglePass[ input_Times ] :=
       Return[input] /; LeafCount[input]===3;

  NCSimplify1RationalSinglePass[expr2_] :=
       Module[ { K, A, B, a, b, c, d, e, expr3 },
          SetCommutative[K,A,B];
          SetNonCommutative[a,b,c,d,e,x,y];

  (* Good[x] is fine as is, Symbolic Commutative elem. should also fail,
  if there is any chance of them becoming zero, *)

          (* BEGIN MAURICIO MAR 2016 *)
          (* WHATCH OUT FOR THE B's ON THE RHS!
          Good[x__] := CommutativeQ[x] && Not[x==1] && Not[x==0];
          normrule := 
             { 
                inv[A_?Good + B_ x_ ** y___] -> inv[A]**inv[Id + (B/A)x**y],
                inv[A_?Good +  x_ ** y___] -> inv[A]**inv[Id + (B/A)x**y],
                inv[A_?Good + B_ x_] -> inv[A]**inv[Id + (B/A)x],
                inv[A_?Good + x_] -> inv[A]**inv[Id + (B/A)x] 
             };
          ( * FIX * )
          Good[x__] := CommutativeQ[x] && Not[x===1] && Not[x===0];
          normrule := 
             { 
                inv[A_?Good + B x_?NonCommutativeQ] -> inv[A]**inv[Id + (B/A)x]
                 ,
                inv[A_?Good + x_] -> inv[A]**inv[Id + (1/A)x]
             };
          *)
          (* END MAURICIO MAR 2016 *)

          (*---------------------------RULE 1---------------------------*) 
          (* rule 1 is as follows:                                      *) 
          (*	inv[a] inv[1 + K a b] -> inv[a] - K b inv[1 + K a b]    *) 
          (*	inv[a] inv[1 + K a] -> inv[a] - K inv[1 + K a]          *)
          (*------------------------------------------------------------*)
          rule[1] :=
          {
          (d___) ** inv[a__] ** inv[Id + (K_.)*(a__) ** (b__)] ** (e___):>
          (*  OutputForm:  d ** inv[a] ** e - K*d ** b ** inv[Id + K*a ** b] ** e  *)
          Plus[NonCommutativeMultiply[d, inv[a], e], Times[-1, K,
             NonCommutativeMultiply[d, b, inv[Plus[Id, Times[K,
             NonCommutativeMultiply[a, b]]]], e]]]
          ,
          (d___) ** inv[a_] ** inv[Id + (K_.)*(a_)] ** (e___):>
          (*  OutputForm:  d ** inv[a] ** e - K*d ** inv[Id + K*a] ** e  *)
          Plus[NonCommutativeMultiply[d, inv[a], e], Times[-1, K,
          NonCommutativeMultiply[d, inv[Plus[1, Times[K, a]]], e]]]
          };

          rule[1] := {
              d___ ** inv[a__] ** inv[1 + K_. a__ ** b__] ** e___ :> 
                  d ** inv[a] ** e - K d ** b ** inv[1 + K a ** b] ** e,
              d___ ** inv[a_] ** inv[1 + K_. a_] ** e___ :> 
                  d ** inv[a] ** e - K d ** inv[1 + K a] ** e
          };
          
          (*-----------------------RULE 2-------------------------------*) 
          (* rule 2 is as follows:                                      *) 
          (*	inv[1 + K a b] inv[b] -> inv[b] - K inv[1 + K a b] a    *) 
          (*	inv[1 + K a] inv[a] -> inv[a] - K inv[1 + K a ]         *) 
          (*------------------------------------------------------------*)
          rule[2] :=
          {
          (d___) ** inv[Id + (K_.)*(a__) ** (b__)] ** inv[b__] ** (e___):>
          (*  OutputForm:  d ** inv[b] ** e - K*d ** inv[Id + K*a ** b] ** a ** e  *)
          Plus[NonCommutativeMultiply[d, inv[b], e],
          Times[-1, K, NonCommutativeMultiply[d, inv[Plus[1,
          Times[K, NonCommutativeMultiply[a, b]]]], a, e]]]
          ,
          (d___) ** inv[Id + (K_.)*a_] ** inv[a_] ** (e___):>
          (*  OutputForm:  d ** inv[a] ** e - K*d ** inv[Id + K*a] ** e  *)
          Plus[NonCommutativeMultiply[d, inv[a], e],
          Times[-1, K, NonCommutativeMultiply[d, inv[Plus[1, Times[K, a]]], e]]]
          };

          rule[2] := {
              d___ ** inv[1 + K_. a__ ** b__] ** inv[b__] ** e___ :> 
                  d ** inv[b] ** e - K d ** inv[1 + K a ** b] ** a ** e,
              d___ ** inv[1 + K_. a_] ** inv[a_] ** e___ :> 
                  d ** inv[a] ** e - K d ** inv[1 + K a] ** e
          };

          (*-------------------------------RULE 3------------------*) 
          (* rule 3 is as follows:                                 *)
          (*     inv[1 + K a b ] a b -> (1 - inv[1 + K a b])/K     *)
          (*     inv[1 + K a] a -> (1 - inv[1 + K a])/K            *) 
          (*-------------------------------------------------------*)
          rule[3] :=
          {
          (d___) ** inv[Id + (K_.)*(a__) ** (b__)] ** (a__) ** (b__) ** (e___):>
          (*  OutputForm:  (d ** e + -1*d ** inv[Id + K*a ** b] ** e)/K  *)
          Times[Power[K, -1], Plus[NonCommutativeMultiply[d, e],
          Times[-1, NonCommutativeMultiply[d, inv[Plus[1,
          Times[K, NonCommutativeMultiply[a, b]]]], e]]]]
          , 
          (d___) ** inv[Id + (K_.)*(a_)] ** (a_) ** (e___):>
          (*  OutputForm:  (d ** e + -1*d ** inv[Id + K*a] ** e)/K  *)
          Times[Power[K, -1], Plus[NonCommutativeMultiply[d, e],
          Times[-1, NonCommutativeMultiply[d, inv[Plus[1, Times[K, a]]], e]]]]
          };

          rule[3] := {
              d___ ** inv[1 + K_. a__ ** b__] ** a__ ** b__ ** e___ :> 
                  (1/K) d ** e - (1/K) d ** inv[1 + K a ** b] ** e,
              d___ ** inv[1 + K_. a_] ** a_ ** e___ :> 
                  (1/K) d ** e - (1/K) d ** inv[1 + K a] ** e
          };

          (*---------------------------RULE 3'------------------------*) 
          (* inv[1 + c + K a b] a b                                   *)
          (*         -> [1 - inv[1 + c + K a b] (1 + c)]/K            *)
          (* inv[1 + c + K a] a -> [1 - inv[1 + c + K a] (1 + c)]/K   *)
          (*----------------------------------------------------------*)
             
          rule[3] := {
              d___ ** inv[1 + c_. + K_. a__ ** b__] ** a__ ** b__ ** e___ :> 
                  (1/K) d ** e - (1/K) d ** inv[1 + c + K a ** b] ** (1 + c) ** e,
              d___ ** inv[1 + c_. + K_. a_] ** a_ ** e___ :> 
                  (1/K) d ** e - (1/K) d ** inv[1 + c + K a] ** (1 + c) ** e
          };

          rule[3] := {
              d___ ** inv[c_ + K_. a__ ** b__] ** a__ ** b__ ** e___ :> 
                  (1/K) d ** e - (1/K) d ** inv[c + K a ** b] ** c ** e,
              d___ ** inv[c_ + K_. a_] ** a_ ** e___ :> 
                  (1/K) d ** e - (1/K) d ** inv[c + K a] ** c ** e
          };

          (*----------------------RULE 4---------------------------*) 
          (* rule 4 is as follows:                                 *)
          (*     a b inv[1 + K a b] -> (1 - inv[1 + K a b])/K      *)
          (*	 a inv[1 + K a] -> (1 - inv[1 + K a])/K            *)
          (*-------------------------------------------------------*)
          rule[4] :=
          {
          (d___) ** (a__) ** (b__) ** inv[Id + (K_.)*(a__) ** (b__)] ** (e___):>
          (*  OutputForm:  (d ** e + -1*d ** inv[Id + K*a ** b] ** e)/K  *)
          Times[Power[K, -1], Plus[NonCommutativeMultiply[d, e],
          Times[-1, NonCommutativeMultiply[d, inv[Plus[1,
          Times[K, NonCommutativeMultiply[a, b]]]], e]]]]
          ,
          (d___) ** (a_) ** inv[Id + (K_.)*(a_)] ** (e___):>
          (*  OutputForm:  (d ** e + -1*d ** inv[Id + K*a] ** e)/K  *)
          Times[Power[K, -1], Plus[NonCommutativeMultiply[d, e],
          Times[-1, NonCommutativeMultiply[d, inv[Plus[1, Times[K, a]]], e]]]]
          };

          rule[4] := {
              d___ ** a__ ** b__ ** inv[1 + K_. a__ ** b__] ** e___ :> 
                  (1/K) d ** e - (1/K) d ** inv[1 + K a ** b] ** e,
              d___ ** a_ ** inv[1 + K_. a_] ** e___ :> 
                  (1/K) d ** e - (1/K) d ** inv[1 + K a] ** e
          };

          (*---------------------------RULE 4'------------------------*) 
          (* a b inv[1 + c + K a b]                                   *)
          (*         -> [1 - (1 + c) inv[1 + c + K a b]]/K            *)
          (* a inv[1 + c + K a] -> [1 -  (1 + c) inv[1 + c + K a]]/K  *)
          (*----------------------------------------------------------*)

          rule[4] := {
              d___ ** a__ ** b__ ** inv[1 + c_. + K_. a__ ** b__] ** e___ :> 
                  (1/K) d ** e - (1/K) d ** (1 + c) ** inv[1 + c + K a ** b] ** e,
              d___ ** a_ ** inv[1 + c_. + K_. a_] ** e___ :> 
                  (1/K) d ** e - (1/K) d ** (1 + c) ** inv[1 + K a] ** e
          };
          
          rule[4] := {
              d___ ** a__ ** b__ ** inv[c_ + K_. a__ ** b__] ** e___ :> 
                  (1/K) d ** e - (1/K) d ** c ** inv[c + K a ** b] ** e,
              d___ ** a_ ** inv[c_ + K_. a_] ** e___ :> 
                  (1/K) d ** e - (1/K) d ** c ** inv[1 + K a] ** e
          };

          (*---------------------------------RULE 5---------------------*) 
          (* rule 5 is as follows:                                      *) 
          (*	 inv[1 + K a b] inv[a] -> inv[a] inv[1 + K b a]         *)
          (*	 inv[1 + K a] inv[a] -> inv[a] inv[1 + K a]             *)
          (*------------------------------------------------------------*)
          rule[5] :=
          {
          (d___) ** inv[Id + (K_.)*(a__) ** (b__)] ** inv[a__] ** (e___):>
          (*  OutputForm:  d ** inv[a] ** inv[Id + K*b ** a] ** e  *)
          NonCommutativeMultiply[d, inv[a], inv[Plus[1,
          Times[K, NonCommutativeMultiply[b, a]]]], e]
          ,
          (d___) ** inv[Id + (K_.)*(a_)] ** inv[a_] ** (e___):>
          (*  OutputForm:  d ** inv[a] ** inv[Id + K*a] ** e  *)
          NonCommutativeMultiply[d, inv[a], inv[Plus[1, Times[K, a]]], e]
          };

          rule[5] := {
              d___ ** inv[1 + K_. a__ ** b__] ** inv[a__] ** e___ :> 
                  d ** inv[a] ** inv[1 + K b ** a] ** e,
              d___ ** inv[1 + K_. a_] ** inv[a_] ** e___ :> 
                  d ** inv[a] ** inv[1 + K a] ** e
          };

          (*---------------------------------RULE 5'--------------------*) 
          (* inv[1 + c + K a b] inv[a]                                  *)
          (*     -> inv[a] inv[1 + c + K b a]                           *)
          (* inv[1 + c + K a] inv[a]                                    *)
          (*     -> inv[a] inv[1 + c + K a]                 *)
          (*------------------------------------------------------------*)

          (*
          inv[a] inv[1 + K a] (1 + K a) = inv[a]
          <- 
          inv[1 + K a] inv[a] (1 + K a) ==
          inv[1 + K a] (inv[a] + K) ==
          inv[1 + K a] (inv[a] + K) ==
          *)

          (*---------------------------------RULE 6---------------------*) 
          (* rule 6 is as follows:                                      *)
          (*      inv[1 + K a b] a  =  a inv[1 + K b a]                 *) 
          (*------------------------------------------------------------*)
          rule[6] :=
          {
          (d___) ** inv[Id + (K_.)*(a__) ** (b__)] ** (a__) ** (e___):>
          (*  OutputForm:  d ** a ** inv[Id + K*b ** a] ** e  *)
          NonCommutativeMultiply[d, a, inv[Plus[1,
          Times[K, NonCommutativeMultiply[b, a]]]], e]
          };

          (* ?? WHY NOT SECOND RULE ?? *)
          rule[6] := {
              d___ ** inv[1 + K_. a__ ** b__] ** a__ ** e___ :> 
                  d ** a ** inv[1 + K b ** a] ** e,
              d___ ** inv[1 + K_. a_] ** a_ ** e___ :> 
                  d ** a ** inv[1 + K a] ** e
          };

          (* BEGIN MAURICIO MAR 2016 *)
          (* expr3 = expr2 //. normrule; *)
          (* END MAURICIO MAR 2016 *)
          expr3 = NCSimplifyRational`NCNormalizeInverse[expr2];
          (* Print["expr3 = ", expr3]; *)
          
          For[ n=1, n <= 6, n++,
               (* expr3 = Expand[Transform[expr3, rule[n]]]; *)
               expr3 = ExpandAll[ExpandNonCommutativeMultiply[NCReplaceRepeated[expr3, rule[n]]]];
          ];
          Return[ expr3 ]
  ];

End[ ]

EndPackage[ ]
