---
layout: post
title:  "Finite abstract algebra in Haskell, Part I: Introduction"
date:   2021-06-13 11:55:46 -0700
categories: haskell mathematics
---

Group theory is one of the most beguiling topics in mathematics. The core
concepts -- groups, subgroups, homomorphisms, cosets, etc. -- are remarkably
easy to define and understand, but this apparently simple set of concepts gives
rise to incredible complexity and beauty.

Ever since I was introduced to the topic, I've wanted to formalize these elegant
concepts in a computational setting where I could explore various examples of
groups, peel them apart, construct quotients and morphisms with them, look at
their cayley subgroup diagrams, and generally "play" with groups in order to
understand them in a concrete and intuitive way.

In this series of blog posts, I'll be describing a [Haskell
library](http://github.com/benjaminselfridge/finite-algebra) I'm working on to allow me
to play with small(-ish) finite groups and to explore group-theoretic ideas in a
practical setting.

Definition of a group
--

The type class approach
==
Haskell has a number of implementations of the concept of a group. See:

- [groups](https://hackage.haskell.org/package/groups-0.5.2/docs/Data-Group.html)
- [group-theory](https://hackage.haskell.org/package/group-theory-0.2.2/docs/Data-Group.html)
- [magmas](https://hackage.haskell.org/package/magmas-0.0.1/docs/Data-Group.html)

All of the formalizations above use a type class to define the concept of a
group. This approach takes the view that *sets* in mathematics correspond to
*types* in Haskell:

```haskell
class Semigroup g where
  (<>) :: g -> g -> g
  
class Semigroup g => Monoid g where
  mempty :: g

class Monoid g => Group g where
  invert :: g -> g
```

We can define law-abiding instances for many types, including `Integer`:

```haskell
instance Semigroup Integer where
  (<>) = (+)
instance Monoid Bool where
  mempty = 0
instance Group Bool where
  invert = negate
```

Formalizing groups in this way allows us to turn any Haskell type into a group
by specifying what the multiplication, identity, and inversion operations are
for that type. It takes advantage of Haskell's type class mechanism and builds
on core Haskell notions of `Semigroup` and `Monoid`. 

However, it is hard to use this definition in practice if the goal is to
understand more about groups. As an example, one of the first groups we learn
about in abstract algebra is the integers mod some positive integer `n`. To
define this group using our `Group` type class, we first need to define a new
type (since each type has *at most* one group instance):

```haskell
data Zn = Zn { znVal :: Integer
             , znModulus :: Integer -- ^ Must be > 0.
             }
             
-- | Smart constructor for 'Zn'.
zn :: Integer -- ^ representative
   -> Integer -- ^ modulus
   -> Zn
zn i n = Zn (i `mod` n)
```

So, we have defined our type that we can define a group instance over, `Zn`, and
a smart constructor to create elements of this group. It is pretty
straightforward to define the `Semigroup` instance:

```haskell
instance Semigroup Zn where
  Zn i n <> Zn j n' | n == n' = zn (i+j)
                    | otherwise = error "can't add Zn of different modulus"
```

To add to `Zn`s together, first check that their moduli are the same (otherwise
they are not even in the same group!), and throw an error if they are not. If
they are the same, perform addition `mod n`.

Once we try to define a `Monoid` instance, however, we run into a bit of trouble:

```haskell
instance Monoid Zn where
  mempty = Zn 0 _ -- ??? What is the modulus?
```

Obviously, the identity element for `Zn` would have to be `0`. But *which* `0`
do we mean? We need to know what to put for the modulus, but there are a lot of
choices.

The problem we have is that `Zn` doesn't just correspond to one group --
it corresponds to many!

We have two choices if we wish to proceed:
1. Use fancy Haskell types to encode the modulus into the type somehow
2. Abandon the type class approach and try something different

The first option is quite appealing, and leads to something like this:

```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}

import Data.Parameterized.NatRepr
import GHC.TypeLits

data Zn (n :: Nat) where
  Zn :: NatRepr n -> Integer -> Zn n
  
instance Semigroup (Zn n) where
  (Zn n i) <> (Zn _ j) = Zn n ((i + j) `mod` intValue n)
instance KnownNat n => Monoid (Zn n) where
  mempty = Zn knownNat 0
instance KnownNat n => Group (Zn n) where
  invert (Zn n i) = Zn n (negate i `mod` n)
```

However, I find it annoying to create a new type every time I want to mess
around with a new kind of group. Among other things, it makes it very annoying
to talk about subgroups of a group. For this project, I chose a different
approach.

The data type approach
==

I'm interested in constructing *finite* groups and messing around with them as
sets with operations on them. I want to be able to use the same underlying type
(say, `Integer`) to build two totally different groups. The type of the elements
is not what is important to me -- those are just a set of names to use. What's
important is the set of values that comprise the group, as well as the
particular operations that are defined on that set. With this in mind, I came up
with the following:

```haskell
import Data.Set (Set)

data Group a where
  set :: Set a       -- ^ Elements of the group.
  mul :: a -> a -> a -- ^ Group multiplication.
  inv :: a -> a      -- ^ Inversion.
  e   :: a           -- ^ Identity.
```

Ironically, this is actually a bit more obvious than the type class-based
approach from mathematical standpoint. Indeed, you can use the same underlying
set to define totally different group structures. We can use integers to
represent elements of `Z4`, the integers mod `4`, or `Z2 x Z2`, the direct
product of the group of integers mod `2` with itself. We can use integers to
represent the elements of both groups, but no matter how we name those elements,
the two groups will have totally different multiplication tables. Below, we show
how to use the `finite-algebras` library to inspect these two groups:

```
>>> import Algebra.Finite.Class
>>> import Algebra.Finite.Group
>>> import Algebra.Finite.Group.Zn
>>> import Algebra.Finite.Group.Symmetric
>>> z4 = znAdditive 4
>>> putStrLn $ ppMulTable z6
 |0|1|2|3
-+-+-+-+-
0|0|1|2|3
-+-+-+-+-
1|1|2|3|0
-+-+-+-+-
2|2|3|0|1
-+-+-+-+-
3|3|0|1|2
>>> z2 = znAdditive 2
>>> z2xz2 = ghCodomain $ integerRenaming $ directProduct z2 z2
>>> putStrLn $ ppMulTable z2xz2
 |0|1|2|3
-+-+-+-+-
0|0|1|2|3
-+-+-+-+-
1|1|0|3|2
-+-+-+-+-
2|2|3|0|1
-+-+-+-+-
3|3|2|1|0
```

The two groups are so different that you can't even rename elements to make the
multiplication tables agree. This is easily seen by examining the diagonal -- in
`z4`, there are two idempotent elements (elements `x` satisfying `xx = e`), but
in `z2xz2`, all four group elements are idempotent! Multiplication just *works
differently* in these two groups. However, nothing is stopping us from defining
them, and even using the same underlying element type (`Integer`) to name the
group elements:

```
>>> :t z4
Group Integer
>>> :t z2xz2
Group Integer
```

With this approach, it requires less overhead to construct my own groups on the
fly. I don't have to define a new type; I can use an existing type to create
names for the group elements I wish to include, and then provide custom
definitions of the three group operations for maximum flexibility.

Group laws
--

Recall that a group must satisfy some basic axioms:

* (Associativity) `forall a b c in g . (ab)c = a(bc)`
* (Identity) `forall a in g . ea = ae = a`
* (Inversion) `forall a in g . (inv a)a = a(inv a) = e`

Because our formulation of a group is finite, we can verify these axioms hold
for any group we might like to define using the `checkAlgebra` function from
`Algebra.Finite.Class`:

```
>>> a # b = (a + b) `mod` 2
>>> neg a = negate a `mod` 2
>>> g = Group (Set.fromList [0, 1::Integer]) (#) neg 0
>>> checkAlgebra g
Nothing
```

The result `Nothing` indicates that `g` is a valid group; the group axioms hold
for the operations of `g`. Let's see what happens if we try to build a group
with an invalid multiplication operation:

```
>>> _ ## _ = 0
>>> bad = Group (Set.fromList [0, 1::Integer]) (##) neg 0
>>> putStrLn $ ppMulTable bad
 |0|1
-+-+-
0|0|0
-+-+-
1|0|0
>>> checkAlgebra bad
Just (IdLeftIdentity,[1])
```

The result `Just (IdLeftIdentity,[1])` means that the identity element `0` is in
fact *not* a left identity, with `1` being a counterexample. Indeed, looking at
the multiplication table, we see that `0 * 1` is `0`, not `1`, as it should be.

What if we forget to use modular addition, and instead use the `+` operator?

```
>>> bad2 = Group (Set.fromList [0, 1::Integer]) (+) neg 0
>>> putStrLn $ ppMulTable bad2
 |0|1
-+-+-
0|0|1
-+-+-
1|1|2
```

This is terrible! The binary operation isn't even well-defined on our group; one
of its results (`2`) doesn't belong to the group's underlying set. Let's check
it using `checkAlgebra`:

```
>>> checkAlgebra bad2
Just (MulClosed,[1,1])
```

The result `Just (MulClosed,[1,1])` means that multiplication is not closed,
with `1` and `1` being counterexamples, since `1 + 1 = 2` is not an element of
our group.

What next?
--

In part II, I'll demonstrate how to use
[finite-algebra](http://github.com/benjaminselfridge/finite-algebra) to
construct homomorphisms and quotient groups, and I'll show off some more
interesting examples of groups.
