#[warnings="-notation-overridden -ambiguous-paths -notation-incompatible-prefix"]
From CFML Require Import WPLib.
From Literate.Lib Require Import WPUntyped.

Implicit Types (p q: loc).

Ltac auto_tilde ::=
  intros; subst; try solve [ intuition eauto with maths ].

Definition head : field := 0%nat.
Definition tail : field := 1%nat.

Notation "'MCell' x q" :=
  (Record `{ head := x; tail := q })
  (at level 19, x at level 0, q at level 0).

Fixpoint MListSeg [A] `{EA: Enc A} q (L: list A) p : hprop :=
  match L with
  | nil => \[p = q]
  | x::L' => \exists (p':loc), (p ~> MCell x p') \* (p' ~> MListSeg q L')
  end.

Lemma MListSeg_nil: forall p q A `{EA: Enc A},
  p ~> (MListSeg q (@nil A)) = \[p = q].
Proof using. intros. xunfold~ MListSeg. Qed.
Global Arguments MListSeg_nil : clear implicits.

Lemma MListSeg_cons: forall p q A `{EA: Enc A} x (L:list A),
  p ~> MListSeg q (x::L) =
  \exists (p':loc), (p ~> MCell x p') \* p' ~> MListSeg q L.
Proof using. intros. xunfold~ MListSeg. Qed.
Global Arguments MListSeg_cons : clear implicits.

Lemma MListSeg_nil_intro : forall p A `{EA:Enc A},
  \[] = p ~> MListSeg p (@nil A).
Proof using. intros. rewrite MListSeg_nil. xsimpl*. Qed.
Global Arguments MListSeg_nil_intro : clear implicits.

Lemma MCell_conflict : forall p1 p2 A1 `{EA1:Enc A1} A2 `{EA2:Enc A2} (x1 x2:A1) (y1 y2:A2),
  p1 ~> MCell x1 y1 \* p2 ~> MCell x2 y2 ==+> \[p1 <> p2].
Proof using.
  intros. tests: (p1 = p2).
  - xchange Heapdata_record.
  - xsimpl*.
Qed.
Global Arguments MCell_conflict : clear implicits.

Lemma MListSeg_MCell_conflict : forall p q A `{EA:Enc A} (L: list A) (x: A) q',
  p ~> MListSeg q L \* q ~> MCell x q' ==+> \[L = nil <-> p = q].
Proof using.
  intros. destruct L.
  - xchanges* MListSeg_nil. split*.
  - xchange MListSeg_cons ;=> p'. tests: (p = q).
    + xchange (@MCell_conflict q q A EA loc Enc_loc).
    + xsimpl; [split*; intros H; invert H | xchange <- MListSeg_cons].
Qed.
Global Arguments MListSeg_MCell_conflict : clear implicits.

Lemma MListSeg_concat : forall p1 p3 A `{EA: Enc A} (L1 L2: list A),
  p1 ~> MListSeg p3 (L1++L2) =
  \exists p2, p1 ~> MListSeg p2 L1 \* p2 ~> MListSeg p3 L2.
Proof using.
  intros. gen p1. induction L1 as [| x L1']; intros; rew_list.
  - xpull.
    + applys himpl_hexists_r p1. xchange~ <- MListSeg_nil.
    + xpull ;=> p2. xchange~ MListSeg_nil ;=> ->.
  - rewrite MListSeg_cons. xpull.
    + intros p1'. xchanges~ IHL1'. xchange <- MListSeg_cons.
    + intros p1'. xchange MListSeg_cons. xchanges <- IHL1'.
Qed.
Global Arguments MListSeg_concat : clear implicits.

Ltac auto_tilde ::= auto_tilde_default.
