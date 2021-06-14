---
layout: page
title:  "Finite abstract algebra in Haskell"
author: Ben Selfridge
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
their Cayley subgroup diagrams, and generally "play" with groups in order to
understand them in a concrete and intuitive way.

In this blog post, I'll be describing a [Haskell
library](http://github.com/benjaminselfridge/finite-algebra) I'm working on to
allow me to play with small finite groups and to explore group-theoretic ideas
in a practical setting.

Definition of a group
--

Below is my definition of a group in Haskell:

```haskell
data Group a = Group { set :: Set a       -- ^ Elements of the group.
                     , mul :: a -> a -> a -- ^ Group multiplication.
                     , inv :: a -> a      -- ^ Inversion.
                     , e   :: a           -- ^ Identity.
                     }
```

A group is just a `Set` of elements with multiplication, inversion, and
identity, just like in mathematics. Let's define a simple example group:

```
>>> z3 = znAdditive 3
```

The `znAdditive` function constructs the group of integers mod `n` for any
positive `n`. We can print `z3`'s multiplication table:

```
>>> p = putStrLn . ppMulTable
>>> p z3
 |0|1|2
-+-+-+-
0|0|1|2
-+-+-+-
1|1|2|0
-+-+-+-
2|2|0|1
```

We can also check that the group axioms hold:

```
>>> checkAlgebra z3
Nothing
```

A result of `Nothing` means all the group axioms hold and this is a valid group.
If we create an invalid group, this function will tell us which axiom fails and
why:

```
>>> checkAlgebra z3 { inv = \a -> negate a }
Just (InvClosed,[1])
```

The result `Just (InvClosed, [1])` tells us that the inverse operation is not
closed, because `negate 1 == -1`, which is not an element of `[0, 1, 2]`. Let's
try another invalid group, this time changing addition slightly:

```
>>> checkAlgebra z3 { mul = \a b -> if (a, b) == (1,1) then 1 else (a + b) `mod` 3}
Just (MulAssoc,[1,1,2])
```

This tells us that our group multiplication operation is not associative, and in
particular, `1*(1*2) /= (1*1)*2`.

More examples
--

Symmetric groups
===

Given a set of `n` elements, we can construct the group of permutations of those
elements:

```
>>> s3 = sn 3
>>> p s3
       |[1,2,3]|[1,3,2]|[2,1,3]|[2,3,1]|[3,1,2]|[3,2,1]
-------+-------+-------+-------+-------+-------+-------
[1,2,3]|[1,2,3]|[1,3,2]|[2,1,3]|[2,3,1]|[3,1,2]|[3,2,1]
-------+-------+-------+-------+-------+-------+-------
[1,3,2]|[1,3,2]|[1,2,3]|[3,1,2]|[3,2,1]|[2,1,3]|[2,3,1]
-------+-------+-------+-------+-------+-------+-------
[2,1,3]|[2,1,3]|[2,3,1]|[1,2,3]|[1,3,2]|[3,2,1]|[3,1,2]
-------+-------+-------+-------+-------+-------+-------
[2,3,1]|[2,3,1]|[2,1,3]|[3,2,1]|[3,1,2]|[1,2,3]|[1,3,2]
-------+-------+-------+-------+-------+-------+-------
[3,1,2]|[3,1,2]|[3,2,1]|[1,3,2]|[1,2,3]|[2,3,1]|[2,1,3]
-------+-------+-------+-------+-------+-------+-------
[3,2,1]|[3,2,1]|[3,1,2]|[2,3,1]|[2,1,3]|[1,3,2]|[1,2,3]
```

Here, the notation `[a,b,c]` denotes the permutation mapping `1` to `a`, `2` to
`b`, and `3` to `c`. Let's rename the permutations to integers to get a bit more
concise-looking table:

```
>>> h = integerRenaming s3
>>> s3' = ghCodomain h
>>> p s3'
 |0|1|2|3|4|5
-+-+-+-+-+-+-
0|0|1|2|3|4|5
-+-+-+-+-+-+-
1|1|0|4|5|2|3
-+-+-+-+-+-+-
2|2|3|0|1|5|4
-+-+-+-+-+-+-
3|3|2|5|4|0|1
-+-+-+-+-+-+-
4|4|5|1|0|3|2
-+-+-+-+-+-+-
5|5|4|3|2|1|0
```

Here, `h` is the isomorphism that renames all the elements of `s3` to integers.

Dihedral groups
===

The dihedral group on `n` vertices is the group of all rotations and symmetries
of a regular `n`-gon. Since this is a subset of all possible permutations of the
vertices, this is also a subgroup of the symmetric group on `n` objects. We can
make this explicit:

```
>>> d4 = dn 4
>>> s4 = sn 4
>>> h = integerRenaming s4
>>> s4' = ghCodomain h
>>> d4' = ghCodomain (restrictHomomorphism h d4)
>>> p d4'
  |0 |5 |7 |9 |14|16|18|23
--+--+--+--+--+--+--+--+--
0 |0 |5 |7 |9 |14|16|18|23
--+--+--+--+--+--+--+--+--
5 |5 |0 |18|23|16|14|7 |9 
--+--+--+--+--+--+--+--+--
7 |7 |9 |0 |5 |18|23|14|16
--+--+--+--+--+--+--+--+--
9 |9 |7 |14|16|23|18|0 |5 
--+--+--+--+--+--+--+--+--
14|14|16|9 |7 |0 |5 |23|18
--+--+--+--+--+--+--+--+--
16|16|14|23|18|5 |0 |9 |7 
--+--+--+--+--+--+--+--+--
18|18|23|5 |0 |7 |9 |16|14
--+--+--+--+--+--+--+--+--
23|23|18|16|14|9 |7 |5 |0 
```

Direct products
--

Given two groups `g` and `h`, we can form the direct product:

```
>>> z2 = znAdditive 2
>>> z2xz2 = z2 `directProduct` z2
>>> p z2xz2
     |(0,0)|(0,1)|(1,0)|(1,1)
-----+-----+-----+-----+-----
(0,0)|(0,0)|(0,1)|(1,0)|(1,1)
-----+-----+-----+-----+-----
(0,1)|(0,1)|(0,0)|(1,1)|(1,0)
-----+-----+-----+-----+-----
(1,0)|(1,0)|(1,1)|(0,0)|(0,1)
-----+-----+-----+-----+-----
(1,1)|(1,1)|(1,0)|(0,1)|(0,0)
```

Homomorphisms
--

The easiest example of a homomorphism is the one that renames the elements of a
group to integers:

```
>>> :t integerRenaming
integerRenaming :: Ord a => Group a -> GroupHomomorphism a Integer
>>> phi = integerRenaming z2xz2
>>> p $ ghCodomain phi
 |0|1|2|3
-+-+-+-+-
0|0|1|2|3
-+-+-+-+-
1|1|0|3|2
-+-+-+-+-
2|2|3|0|1
-+-+-+-+-
3|3|2|1|0
>>> morphismTable phi
[((0,0),0),((0,1),1),((1,0),2),((1,1),3)]
```

This is, in fact, a group isomorphism. Let's construct another homomorphism,
this time one that is not an isomorphism:

```
>>> :t GroupHomomorphism
GroupHomomorphism
  :: Group a -> Group b -> (a -> b) -> GroupHomomorphism a b
>>> phi = GroupHomomorphism z2xz2 z2 fst
>>> checkMorphism phi
Nothing
```

Here, `phi` is the projection homomorphism that simply forgets about the second
element.

```
>>> morphismTable phi
[((0,0),0),((0,1),0),((1,0),1),((1,1),1)]
```

We can actually specify a morphism by specifying its behavior on a generative
subset of the domain:

```
>>> z4 = znAdditive 4
>>> phi = generatedHomomorphism z4 z2 [(1, 1)]
>>> morphismTable phi
[(0,0),(1,1),(2,0),(3,1)]
```

Even though we didn't specify where anything besides `1` is mapped to, the
function computed the values that the other elements must be mapped to based on
the homomorphism law because `{1}` is a generative subset of `z4`. `{2}`,
however, is not generative, so let's see what happens if we use that instead:

```
>>> phi = generatedHomomorphism z4 z2 [(2, 1)]
>>> morphismTable phi
[(0,0),(2,1)]
>>> set $ ghDomain phi
{0,2}
```

Because the homomorphism was specified for a non-generative subset of `z4`, we
didn't end up with a full map from `z4` to `z2`; the domain of the resulting
homomorphism was the subgroup `{0, 2}`.

Quotient groups
--

Given a homomorphism phi, we can compute its kernel:

```
>>> phi = generatedHomomorphism z4 z2 [(1, 1)]
>>> set $ kernel phi
{0, 2}
```

We know that the kernel of any homomorphism is a normal subgroup of the domain
of the homomorphism:

```
>>> kernel phi `isNormalSubgroupOf` z4
True
```

This means we can take the quotient `z4 / kernel phi`:

```
>>> g = z4 `quotientGroup` kernel phi
>>> set g
{% raw %}{{0,2},{1,3}}{% endraw %}
>>> p g
     |{0,2}|{1,3}
-----+-----+-----
{0,2}|{0,2}|{1,3}
-----+-----+-----
{1,3}|{1,3}|{0,2}
>>> checkAlgebra g
Nothing
```

Because `kernel phi` is normal, this is a well-formed construction. If we pick a
non-normal subgroup, bad things will happen:

```
>>> import qualified Algebra.Finite.Set as Set
>>> h = generated s3 (Set.fromList [fromList [2, 1, 3]])
>>> p h
       |[1,2,3]|[2,1,3]
-------+-------+-------
[1,2,3]|[1,2,3]|[2,1,3]
-------+-------+-------
[2,1,3]|[2,1,3]|[1,2,3]
```

This is the subgroup of `s3` generated by the permutation that swaps two
elements. This subgroup is isomorphic to `z2`, but it is not a normal subgroup:

```
>>> h `checkNormalSubgroupOf` s3
Just [1,3,2]
```

This means that the permutation `[1,3,2]` is an example of an element `a` such
that `a * h * a^-1 /= h`:

```
>>> conjugateSet s3 (fromList [1,3,2]) (set h)
{[1,2,3],[3,2,1]}
```

What happens if we still try to take the quotient group anyway?

```
>>> q = s3 `quotientGroup` h
>>> checkAlgebra q
Just (MulClosed,[{[1,2,3],[2,1,3]},{[1,3,2],[3,1,2]}])
```

The problem here is that although we can take the cosets of `h`, multiplication
is not closed; in particular, when we multiply the cosets `{[1,2,3],[2,1,3]}`
and `{[1,3,2],[3,1,2]}` we get something that is not a coset:

```
>>> mul q (Set.fromList [fromList [1,2,3],fromList [2,1,3]]) (Set.fromList [fromList [1,3,2],fromList [3,1,2]])
{[1,3,2],[2,3,1],[3,1,2],[3,2,1]}
```

Not only is this not a coset, it doesn't even have the right number of elements
to be one.

What next?
--

The immediate next goal I have is to produce the Cayley diagram of a group. It's
relatively straightforward to compute every nontrivial subgroup and arrange them
in a lattice, so that will be fun to do whenever I get the chance.

In addition, it would be nice to create similar algebraic constructions for
rings and fields. The `Algebra` type class (not described in this post) handles
a lot of the machinery for checking that all the group laws hold, and this type
class is not biased toward the group axioms or even the group operations.
