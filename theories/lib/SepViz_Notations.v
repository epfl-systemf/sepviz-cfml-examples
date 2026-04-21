#[warnings="-notation-overridden -ambiguous-paths -notation-incompatible-prefix"]
From CFML Require Import WPLib.

(** ** Separation-logic formulas *)

Declare Custom Entry sepviz.

Notation "⟬  e  ⟭" :=
  (e)
    (e custom sepviz at level 200, at level 0).

Notation "'Pure' '┆' P" :=
  (hpure P)
    (in custom sepviz at level 200,
     P constr at level 200).

Notation "'PointsTo' '┆' x '┆' S" :=
  (repr S x)
    (in custom sepviz at level 200,
        x constr at level 200,
        S constr at level 200).

Notation "'Star' '┆' H1 '┆' H2" :=
  (hstar H1 H2)
    (in custom sepviz at level 200,
     H1 constr at level 200,
     H2 constr at level 200).

Notation "'Wand' '┆' H1 '┆' H2" :=
  (hwand H1 H2)
    (in custom sepviz at level 200,
     H1 constr at level 200,
     H2 constr at level 200).

Notation "'Exist' '┆' x '┆' P" :=
  (hexists (fun x => P))
    (in custom sepviz at level 200,
      P constr at level 200).

Notation "'Opaque' '┆' 'GC'" :=
  (hgc)
    (in custom sepviz at level 200).

Notation "'Opaque' '┆' 'emp'" :=
  (hempty)
    (in custom sepviz at level 200).

Notation "'SPEC' t '⟬*' 'PRE' '@' H '*⟭' 'POST' Q" :=
  (Triple t H Q)
    (in custom sepviz at level 200,
      format "'SPEC' t '//' '⟬*'  'PRE'  '@'  H  '*⟭' '//' 'POST' Q").

(** ** disable notations *)

Notation "Q \*+ H" := (fun x => hstar (Q x) H) (only parsing): heap_scope.

Section septest.
  Parameter A B C: hprop.
  Parameter P: Prop.
  Check (hstar A B).
  Check (hstar (hstar A C) B).
  Check (hwand A B).
  Check (hwand (hstar (hstar A A) B) (hpure P)).
End septest.


(** ** Values *)

Declare Custom Entry val.

Notation "'⟦' e '⟧'" :=
  (e)
    (e custom val at level 200, at level 0).
