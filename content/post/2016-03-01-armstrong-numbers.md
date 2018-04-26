---
title: "Armstrong Numbers"
date: 2016-03-01
tags: ["java"]
---


An [Armstrong number](https://en.wikipedia.org/wiki/Narcissistic_number) is "_a number that is the sum of its own digits each raised to the power of the number of digits_"

<!--more-->

For example, `8208` is an Armstrong number because `8208 = 8^4 + 2^4 + 0^4 + 8^4`. We will say that `8208` is a **level-4** number and call the power sum of its digits, an **a-sum**. Single digit
numbers are obviously (**level-1**) Armstrong numbers , all Armstrong numbers up to level 4 are:

|               |                      |
| ------------- |----------------------|
| level-1       | `1 2 3 4 5 6 7 8 9`  |
| level-3       | `153 370 371 407`    |
| level-4       | `1634 8208 9474`     |

There is a finite number of Armstrong numbers, this is because the magnitude of a number grows quicker then it's **a-sum** so that after certain point, the **a-sum** falls behind. The largest Armstrong number is
a level-39ner.



[This code](https://github.com/sorokod/Armstrong) calculates all Armstrong numbers up to level-39 with the following timings:

```
  Level-15 0  sec.   41 numbers
  Level-18 2  sec.   46 numbers
  Level-20 6  sec.   51 numbers
  Level-21 11 sec.   53 numbers
  Level-22 15 sec    53 numbers
  Level-23 21 sec.   58 numbers
  Level-25 46 sec    66 numbers
  Level-39 3518 sec. (58 min) 88 numbers

  (on i7-4790K CPU @ 4.00GHz)

```


<br/>
#### Optimizations

The following optimizations, listed in the order of their impact, are used.

* A neat insight from this [stackoverflow discussion]( http://stackoverflow.com/questions/35487030/java-fast-way-to-check-if-digits-in-int-are-in-ascending-order), is best demonstrated by an example.
Looking at `8208 = aSum(8208) = 8^4 + 2^4 + 0^4 + 8^4`, it is clear that the value of **a-sum** doesn't
depend on the order of the digits. In other words, all numbers comprised of the digits {0,2,8,8}
will have the same **a-sum**. For any **representative** N from the set of numbers comprised of digits
{0,2,8,8}, N is A-number if and only if `a-sum(N) = a-sum(a-sum(N))`. Therefore, generally, we don't need to
examine all numbers up to a given `level` but only one representative from every multiset of digits.
This reduces the search space from `10^39` to about `10^10`.

* It doesn't really matter which representative we pick, the one with digits in descending order is
reasonably easy to work with, e.g. the representative of `{0,2,8,8}` is `8820`. Instead of filtering
all `10^39` values for representatives, the code builds and discards the representatives dynamically
so that only relevant values are examined with modest memory requirement ( [a bit more about that tree](https://github.com/sorokod/Armstrong/blob/master/TREE.md) ).

* Obviously the problem can be broken down into parts that can be executed in parallel.

* Datatypes. The representatives are modeled as byte arrays so that `8820` is `byte[] {8,8,2,0}`
( `BigInteger`s are used to calculate **a-sum**s ).

* Various. For the calculation of **a-sum**s the powers of `{1..9}` are precomputed and cached.
Instead of checking that `a-sum(N) = a-sum(a-sum(N))` it is cheaper to verify that `a-sum(N)` is a permutation
of the digits of `N` which saves us an extra call to `a-sum`.



