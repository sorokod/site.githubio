---
title: Fibonacci
subtitle: Fibonacci with tail recursion in Kotlin
date: 2018-03-16
tags: ["kotlin", "algo", "jmh"]
---

![Fibonacci spiral](/img/fibonacci-sequence.png)

I enjoyed reading the [The Fibonacci Problem blog post](https://blog.des.io/posts/2018-03-08-fibonacci.html) that shows (among other things) a tail recursive algorithm for the Fibonacci sequence.

<!--more-->

The original code is in Golang which has no tail recursion optimization. I wanted to compare the Golang code to Kotlin, see Kotlin's `tailrec` in action and measure the entire thing with [`jmh`](http://openjdk.java.net/projects/code-tools/jmh/).

I retained the original function names (up to capitalization) so the original Golang code: 

{{< highlight go >}}
func FibNaive(n int) int {
    if n < 2 {
        return n
    }   
    return FibNaive(n-1) + FibNaive(n-2)
}
{{</ highlight >}}

looks like so in my version in Kotlin:

{{< highlight kotlin >}}
fun fibNaive(n: Int): Int =
        when (n) {
            0, 1 -> n
            else -> fibNaive(n - 1) + fibNaive(n - 2)
        }
{{</ highlight >}}


>
> Sources are [here](https://github.com/sorokod/kotlin-fibonaccis). To build and run, execute: 
> 
> `mvn clean install && java -jar target/benchmarks.jar`
>

## FibCached

Here, we improve on the naive approach by caching the intermediate results:   

{{< highlight kotlin "linenos=inline">}}
fun fibCached(
    n: Int, 
    cache: MutableMap<Int, Int> = mutableMapOf(Pair(0, 0), Pair(1, 1))): Int =
    
        cache.getOrPut(n) {
            cache.getOrPut(n - 1) { fibCached(n - 1, cache) } +
            cache.getOrPut(n - 2) { fibCached(n - 2, cache) }
        }
{{</ highlight >}}

This gives us over five orders of magnitude improvement over `fibNaive`.

>
> The initial implementation worked around Kotlin not understanding my intent, details are on [StackOverflow](https://stackoverflow.com/questions/49522945/kotlin-getorput-oddness)   
> 
>



## FibVectorSum

The key observation here is that we can replace two recursive calls each returning a scalar ( i.e.  `f(n-1) + f(n-2)` ) with a single recursive
call that returns a vector (a Pair really). 

{{< highlight kotlin "linenos=inline">}}
fun T(p: Pair<Int, Int>): Pair<Int, Int> = Pair(p.first + p.second, p.first)

fun fibVecSum(n: Int): Int {

    fun fibVec(n: Int): Pair<Int, Int> =
            when (n) {
                1 -> Pair(1, 0)
                else -> T(fibVec(n - 1))
            }


    return when (n) {
        0, 1 -> n

        else -> {
            val (a, b) = fibVec(n - 1)
            a + b
        }
    }
}
{{</ highlight >}}

This gives us an order of magnitude improvement over `fibCached`.

Incidentally, there is a a more Kotlin-idiomatic way to implement the same approach using the `generateSequence` function. It doesn't match
 the narrative of the original post though: 

{{< highlight kotlin >}}
fun fibVecSumKotlin(n: Int): Int {

    fun genPairSequence(): Sequence<Pair<Int, Int>> =
            generateSequence(Pair(1, 0), { T(it) })

    return genPairSequence().take(n + 1).last().second
}
{{</ highlight >}}


## FibTailVecSum

The remaining issue in `FibVectorSum` preventing it being tail recursive is the transformation at line 8. This can be fixed by accumulating 
the sum into the recursive call:

{{< highlight kotlin "linenos=inline">}}
fun fibTailVecSum(n: Int): Int {

    tailrec fun fibTailVec(acc: Int, a: Int, b: Int): Pair<Int, Int> =            
            when (acc) {
                1 -> Pair(a, b)
                else -> fibTailVec(acc - 1, a + b, a)
            }
    
    return when (n) {
        0, 1 -> n
        else -> {
            val (a, b) = fibTailVec(n - 1, 1, 0)
            a + b
        }
    }
}
{{</ highlight >}}


Note the `tailrec` decoration of the recursive function at line 3. Once again we have an order of magnitude improvement over the previous take; `fibVectorSum`.



## FibIterative

In the iterative version the `fibTailVec` is replaced by a while loop 

{{< highlight kotlin >}}
fun fibIterative(n: Int): Int {
    if (n < 2) {
        return n
    }

    var acc = n
    var a = 1
    var b = 0
    var tmp = 0

    while (acc > 2) {
        acc--
        tmp = a
        a += b
        b = tmp
    }
    return a + b
}
{{</ highlight >}}

The code is more verbose than the Go version because Kotlin has no "multiple assignments" as in `n, a, b = n-1, a+b, a`. 

It is also the fastest.   

## Benchmarks

Benchmarks were generated using `jmh` with the following configuration:


{{< highlight kotlin >}}

@State(Scope.Benchmark)
@Fork(1)
@Warmup(iterations = 15)
@Measurement(iterations = 15)
@BenchmarkMode(AverageTime)
@OutputTimeUnit(NANOSECONDS)

{{</ highlight >}}



Benchmark              |(n) |        Score   | Units  | Normalaized by `fibIterative`
 -------------         | ---|----------------|------  |------------------------------ 
fibNaive               | 12 |        505.787 |  ns/op | 109
fibNaive               | 40 |  359727438.400 |  ns/op | 32702494
fibCached              | 12 |        490.736 |  ns/op | 106
fibCached              | 40 |       1393.079 |  ns/op | 123
fibVecSum              | 12 |         56.979 |  ns/op | 12
fibVecSum              | 40 |        242.230 |  ns/op | 21
fibVecSumKotlin        | 12 |         99.435 |  ns/op | 21
fibVecSumKotlin        | 40 |        273.117 |  ns/op | 24
fibTailVecSum          | 12 |          8.447 |  ns/op | 2
fibTailVecSum          | 40 |         14.800 |  ns/op | 1
fibIterative           | 12 |          4.666 |  ns/op | 1
fibIterative           | 40 |         11.372 |  ns/op | 1
fibIterativeTabulated  | 12 |         81.520 |  ns/op | 17
fibIterativeTabulated  | 40 |        257.801 |  ns/op | 22
