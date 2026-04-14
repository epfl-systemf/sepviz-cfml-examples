#[warnings="-notation-overridden -ambiguous-paths -notation-incompatible-prefix"]
From CFML Require Import WPLib.

Declare Custom Entry sepviz.

Notation "⟬  e  ⟭" :=
  (e)
    (e custom sepviz at level 200, at level 0).

Notation "'⟬' 'Pure' '┆' P '⟭'" :=
  (hpure P)
    (in custom sepviz at level 200,
     P constr at level 200).

Notation "'⟬' 'PointsTo' '┆' x '┆' S '⟭'" :=
  (repr S x)
    (in custom sepviz at level 200,
        x constr at level 200,
        S constr at level 200).

Notation "'⟬' 'Star' '┆' H1 '┆' H2 '⟭'" :=
  (hstar H1 H2)
    (in custom sepviz at level 200,
     H1 custom sepviz at level 200,
     H2 custom sepviz at level 200).

Notation "'⟬' 'Wand' '┆' H1 '┆' H2 '⟭'" :=
  (hwand H1 H2)
    (in custom sepviz at level 200,
     H1 custom sepviz at level 200,
     H2 custom sepviz at level 200).

Notation "'⟬' 'Exists' '┆' x '┆' P '⟭'" :=
  (hexists (fun x => P))
    (in custom sepviz at level 200,
      P custom sepviz at level 200).

Notation "'⟬' 'Opaque' '┆' 'GC' '⟭'" :=
  (hgc)
    (in custom sepviz at level 200).


Notation "'⟬' 'Opaque' '┆' 'emp' '⟭'" :=
  (hempty)
    (in custom sepviz at level 200).

(** ** disable notations *)

Notation "Q \*+ H" := (fun x => hstar (Q x) H) (only parsing): heap_scope.
