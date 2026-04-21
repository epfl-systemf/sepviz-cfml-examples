#[warnings="-notation-overridden -ambiguous-paths -notation-incompatible-prefix"]
From CFML Require Import WPLib.

(** ** Separation-logic formulas *)

Declare Custom Entry sep.

Notation "⟬  e  ⟭" :=
  (e)
    (e custom sep at level 200, at level 0).

Notation "'Pure' '┆' P" :=
  (hpure P)
    (in custom sep at level 200,
     P constr at level 200).

Notation "'PointsTo' '┆' x '┆' S" :=
  (repr S x)
    (in custom sep at level 200,
        x constr at level 200,
        S constr at level 200).

Notation "'Star' '┆' H1 '┆' H2" :=
  (hstar H1 H2)
    (in custom sep at level 200,
     H1 constr at level 200,
     H2 constr at level 200).

Notation "'Wand' '┆' H1 '┆' H2" :=
  (hwand H1 H2)
    (in custom sep at level 200,
     H1 constr at level 200,
     H2 constr at level 200).

Notation "'Exist' '┆' x '┆' P" :=
  (hexists (fun x => P))
    (in custom sep at level 200,
     x name, (* necessary for binder *)
     P constr at level 200).

Notation "'Opaque' '┆' 'GC'" :=
  (hgc)
    (in custom sep at level 200).

Notation "'Opaque' '┆' 'emp'" :=
  (hempty)
    (in custom sep at level 200).

Notation "'SPEC' t '⟬*' 'PRE' '@' H '*⟭' '⟬*' 'POST' '@' Q '*⟭'" :=
  (Triple t H Q)
    (at level 200,
     t constr at level 200,
     H constr at level 200,
     Q constr at level 200,
     format "'SPEC'  t '//' '⟬*'  'PRE'  '@'  H  '*⟭' '//' '⟬*'  'POST'  '@'  Q  '*⟭'").

Notation "'⟬*' 'PRE' '@' H '*⟭' 'CODE' F '⟬*' 'POST' '@' Q '*⟭'" :=
  (himpl H (Wptag F _ Q))
    (at level 200,
     H constr at level 200,
     F constr at level 200,
     Q constr at level 200,
     format "'⟬*'  'PRE'  '@'  H  '*⟭' '//' 'CODE'  F '//' '⟬*'  'POST'  '@'  Q  '*⟭'").

(* For continuous animation *)
Notation "'⟬*' 'PRE' '@' H1 '*⟭' '==>' '⟬*' 'POST' '@' H2 '*⟭'" :=
  (himpl H1 H2)
    (at level 200,
     H1 constr at level 200,
     H2 constr at level 200,
     format "'⟬*'  'PRE'  '@'  H1  '*⟭' '==>' '⟬*'  'POST'  '@'  H2  '*⟭'").


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
