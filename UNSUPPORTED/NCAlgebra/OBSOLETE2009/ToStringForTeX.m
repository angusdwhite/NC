Clear[ToStringForTeX];
Clear[ToStringForTeXAux];
Clear[TeXSuperscripts];
Clear[TeXSubsAndSups];
Clear[InitTeXStringReplace];
Clear[TeXStringReplace];

Clear[TeXSubscripts];

TeXSubscripts::usage =
  "TeXSubscripts is a program which extracts subscripts from an\
   expression. For example, TeXSubscripts[A22] returns {\"A\",\"22\"}";


ToStringForTeX[x_String] := x;
ToStringForTeX[x_GBMarker] := ToStringForTeX[RetrieveMarker[x]];
ToStringForTeX[x_Plus] := ToStringForTeXAux3[x];
ToStringForTeX[x_dummyPlus] := ToStringForTeXAux3[x];
ToStringForTeX[x_Equal] := ToStringForTeXAux[x," == "];
ToStringForTeX[x_Rule] := ToStringForTeXAux[x,"\\rightarrow "];
(*
ToStringForTeX[Times[-1,x__]] := "-"<>ToStringForTeX[Times[x]];
*)
ToStringForTeX[x_Times] := ToStringForTeXAux2[x,"\\,\n "];
ToStringForTeX[x_NonCommutativeMultiply] := ToStringForTeXAux2[x,"\\,\n "];

ToStringForTeX[x_Rational] := 
Module[{ans,t,b},
  t = Numerator[x];
  b = Denominator[x];
  ans = "";
  If[TrueQ[b<0], t = -t; b = -b;];
  If[TrueQ[t<0], t = -t; ans = "-"];
  ans = StringJoin[ans,"\\frac{",ToStringForTeX[t],
                   "}{",ToStringForTeX[b],"}"];
  Return[ans];
];

(* Juan *)
(* ToStringForTeX[x:(_tp|_Tp| _inv|_Inv| _aj | _Aj)] := 
                 TeXStringReplace[TeXSubsAndSups[x]]; *)

ToStringForTeX[x:(_tp|_Tp|_inv|_Inv|_aj|_Aj|
		_pinv|_Pinv|_PerpL|_PerpR|_PerpL2|_PerpR2)] := 
                 TeXStringReplace[TeXSubsAndSups[x]];

ToStringForTeX[x_MatMult]:= ToStringForTeXAux2[x,"\\,\n"];

ToStringForTeX[x_dummyMatMult]:= ToStringForTeXAux2[x,"\\,\n"];

ToStringForTeX[x_] :=
Module[{head,aList,result},
  If[Length[x]>0
    , head = Head[x];
      aList = Apply[List,x];
      aList = Map[ToStringForTeX,aList];
      aList = Map[{#,","}&,aList];
      aList = Flatten[aList];
      aList = Take[aList,Length[aList]-1];
      result = ToStringForTeX[head];
      result = StringJoin[result,"["];
      result = StringJoin[result,Apply[StringJoin,aList]];
      result = StringJoin[result,"]"];
    , If[Head[x]===Symbol
        , result = TeXStringReplace[TeXSubsAndSups[x]];
        , result = TeXStringReplace[ToString[x]]
      ];
    , Abort[];
  ];
  Return[result];
];

(* Add this line to tpMat file. *)
tpMat[Literal[tpMat[x__]]]:=x;
ToStringForTeX[x_tpMat]:=ToStringForTeX[tpMat[x]]<>"^{T}";
dummytpMat[dummytpMat[x_]]:=x;
ToStringForTeX[x_dummytpMat]:=ToStringForTeX[dummytpMat[x]]<>"^{T}";

ToStringForTeX[x_Hold]:=
Module[{y=x},
  y=y/.tpMat->dummytpMat;
  y=y/.MatMult->dummyMatMult;
  y=y/.MM->dummyMatMult;
  y=y/.Plus->dummyPlus;
  Return[ToStringForTeX[ReleaseHold[y]]]
];

ToStringForTeXAux[x_,s_String] := 
Module[{aList,j,ans},
  aList = Map[ToStringForTeX,
              Apply[List,x]];
  ans = Apply[StringJoin,
              Table[aList[[j]]<>s,{j,1,Length[aList]-1}]];
  ans = ans <> aList[[-1]];  
  Return[ans];
]; 

ToStringForTeXAux2[x_,s_String] := 
Module[{aList,ans="",i,item,len},
  aList=Apply[List,x];
  len = Length[aList];
  Do[item=aList[[i]];
     If[Head[item]===Plus
       ,ans = ans <> "(" <> ToStringForTeX[aList[[i]]] <> ")";
       ,ans = ans <> ToStringForTeX[aList[[i]]];
     ];
     If[Not[i===len] ,ans = ans <> s];
    ,{i,len}
  ];
  Return[ans];
];

ToStringForTeXAux3[x_] := 
Module[{aList,i,ans},
  aList = Apply[List,x];
  ans = ToStringForTeX[aList[[1]]];
  Do[
    If[Head[x[[i]]]===Times
       ,If[(Head[x[[i,1]]]===Integer || Head[x[[i,1]]]===Rational)
                    && x[[i,1]]<0
          ,ans=ans<>" - "<>ToStringForTeX[-x[[i]]];
          ,ans=ans<>" + "<>ToStringForTeX[x[[i]]];
        ];
       ,ans=ans<>" + "<>ToStringForTeX[x[[i]]];
     ];
    ,{i,2,Length[aList]}
  ];
  Return[ans];
]; 

ToStringForTeX[x_List]:=
Module[{result,dims,len,j,k,i},
  dims=Dimensions[x];
  If[Length[dims]==2
    ,result="\\pmatrix {";
     Do[
       Do[
         result=result<>ToStringForTeX[x[[j,k]]]<>" & ";
        ,{k,dims[[2]]-1}
       ];
       result=result<>ToStringForTeX[x[[j,dims[[2]]]]]<>" \\cr \n";
      ,{j,dims[[1]]}
     ];
     result=result<>"}";
    ,len = Length[x];
     result="\\\\";
     Do[result=result<>ToStringForTeX[x[[i]]]<>"\\\\\n";
       ,{i,len-1}
     ];
     If[len==0
       ,result="\\{\\}";
       ,result=result<>ToStringForTeX[x[[len]]]<>"\\\\";
     ];
     ,BadCall["ToStringForTeX",x];
  ];
  Return[result]
];

ToStringForTeXList[vars_List]:=
Module[{result="$\\{"},
  If[Not[Length[vars]===0]
    ,Do[result=result<>ToStringForTeX[vars[[i]]]<>",\n$ $\n";
      ,{i,Length[vars]-1}
     ];
     result=result<>ToStringForTeX[vars[[-1]]];
  ];
  result=result<>"\\}$";
  Return[result]
];
  
TeXSubscripts[var_Symbol]:=TeXSubscripts[ToString[var]];

TeXSubscripts[var_String]:=
Module[{letters=var, subs=""},
  While[DigitQ[StringTake[letters,-1]]
    ,subs=StringJoin[StringTake[letters,-1],subs];
         letters=StringDrop[letters,-1];
  ];
  Return[{letters,subs}];
];

TeXSuperscripts[var_]:=
Module[{ind, super,rest,head,shouldLoop},
  super = "";
  rest = var;
  shouldLoop = True;
  While[shouldLoop,
    head = Head[rest];
    shouldLoop = False; 
    If[Length[rest]===1 
      , If[And[Not[shouldLoop],(head===tp || head=== Tp)]
          , super = StringJoin[super," T "]; 
            rest = rest[[1]];
            shouldLoop = True;
        ];
        If[And[Not[shouldLoop],(head===aj || head=== Aj)]
          , super = StringJoin[super," * "]; 
            rest = rest[[1]];
            shouldLoop = True;
        ];
        If[And[Not[shouldLoop],(head===inv || head=== Inv)]
          , super = StringJoin[super," -1 "]; 
            rest = rest[[1]];
            shouldLoop = True;
        ];
(* Juan *)
        If[And[Not[shouldLoop],(head===pinv || head=== Pinv)]
          , super = StringJoin[super," + "]; 
            rest = rest[[1]];
            shouldLoop = True;
        ];
        If[And[Not[shouldLoop],(head===PerpL)]
          , super = StringJoin[super," \\lfloor "]; 
            rest = rest[[1]];
            shouldLoop = True;
        ];
        If[And[Not[shouldLoop],(head===PerpR)]
          , super = StringJoin[super," \\rfloor "]; 
            rest = rest[[1]];
            shouldLoop = True;
        ];
        If[And[Not[shouldLoop],(head===PerpL2)]
          , super = StringJoin[super," \\lfloor\\negthinspace\\lfloor "]; 
            rest = rest[[1]];
            shouldLoop = True;
        ];
        If[And[Not[shouldLoop],(head===PerpR2)]
          , super = StringJoin[super," \\rfloor\\negthinspace\\rfloor "]; 
            rest = rest[[1]];
            shouldLoop = True;
        ];
    ];
  ];
  If[Head[rest]===Symbol
   , ind = ToString[rest];
   , ind = ToStringForTeX[rest];
  ];
  If[And[Not[super===""],isComplicated[rest]]
    , ind = StringJoin["\\left(",ind,"\\right)"];
  ];
  Return[{ind,super}];
];

isComplicated[x_Symbol] := False;
(* isComplicated[x:(_tp|_Tp|_aj|_Aj|_inv|_Inv)] := 
     isComplicated[x[[1]]]; *)
(* Juan *)
isComplicated[x:(_tp|_Tp|_aj|_Aj|_inv|_Inv|
		_pinv|_Pinv|_PerpL|_PerpR|_PerpL2|_PerpR2)] := 
     isComplicated[x[[1]]];
isComplicated[x_] := True;
isComplicated[x____] := BadCall["isComplicated",x];;

TeXSubsExtra = "{}";
TeXSupsExtra = "{}";
TeXSubsExtra = "";
TeXSupsExtra = "";

TeXSubsAndSups[x_]:=
Module[{supres,subs,result},
  supres=TeXSuperscripts[x];
  subs=TeXSubscripts[supres[[1]]];
  result=subs[[1]];
  If[subs[[2]]!=""
    ,result=StringJoin[result,TeXSubsExtra,"_{",subs[[2]],"}"];
  ];
  If[supres[[2]]!=""
    ,result=StringJoin[result,TeXSupsExtra,"^{",supres[[2]],"}"];
  ];
  Return[result];
];

InitTeXStringReplace[rules___Rule]:=
  TeXStringReplace[st_String]:=StringReplace[st,{rules}];

InitTeXStringReplace[rules_List]:=
  TeXStringReplace[st_]:=StringReplace[ToString[st],rules];

ClearTeXStringReplace[]:=InitTeXStringReplace[{}];

InitTeXStringReplace[{}];



