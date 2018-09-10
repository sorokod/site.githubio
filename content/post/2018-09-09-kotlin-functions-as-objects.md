---
title: "Kotlin - functions are objects"
date: 2018-09-09T18:00:01+01:00
tags: ["kotlin"]
---

![](/img/kotlin.png)

Sometimes it is useful to look at a subject from a slightly different perspective, this provides a sort of mental
["binocular vision"](https://en.wikipedia.org/wiki/Binocular_vision) and allows to flesh out some details that are less obvious otherwise.  

<!--more-->


_**Pica**_: A function is an implementation of the [`Function`](https://github.com/JetBrains/kotlin/blob/1.2.70/core/builtins/src/kotlin/Function.kt) interface and more specifically, **on the JVM**, an implementation
of `Function[n]` interface where n is in `{0..22}` ( [source on Github](https://github.com/JetBrains/kotlin/blob/1.2.70/libraries/stdlib/jvm/runtime/kotlin/jvm/functions/Functions.kt) ). For example, `Function1` is defined as: 

{{< highlight kotlin >}}
/** A function that takes 1 argument. */
public interface Function1<in P1, out R> : Function<R> {
    /** Invokes the function with the specified argument. */
    public operator fun invoke(p1: P1): R
}
{{</highlight>}}



_**Elster**_: This is not how functions are usually presented, show me what you 
mean.


_**Pica**_: With a bit of reflection we have:

{{<highlight kotlin>}}
fun x2(x: Int) = x * 2
println(::x2 is Function1<Int, Int>)   // prints true
{{</highlight>}}

it is also possible to spell out the type a function reference explicitly as 
`Function[n]`:

{{< highlight kotlin >}}
val x2ref: Function1<Int, Int> = ::x2 
{{</highlight>}}

_**Elster**_: Ok, I guess you can write a class that implements `Function1` and 
multiplies it's parameter by two?

_**Pica**_: Yes, something like this:

{{<highlight kotlin>}}
class X2 : Function1<Int, Int> {
   override fun invoke(x: Int) = 2 * x
}

X2() is Function1<Int, Int>   // true
X2() is (Int) -> Int          // true
{{</highlight>}}

and slightly cleaner version using a singleton object:

{{<highlight kotlin>}}
object ox2 : Function1<Int, Int> {
    override fun invoke(x: Int) = 2 * x
}

ox2 is Function1<Int, Int>   // true
ox2 is (Int) -> Int          // true
{{</highlight>}}

_**Elster**_: And this works? I mean, is it semantically the same as `fun x2(x: Int) = x * 2` ?

_**Pica**_: It does, and it is.

{{<highlight kotlin>}}
val x2 = X2()

x2(3)                          // 6
listOf(1,2,3).map(x2)          // [2,4,6]
listOf(1,2,3).map(ox2)         // [2,4,6]
{{</highlight>}}

_**Elster**_: Wait, if in `Function[n]` - n has to be less than 23, what happens if I 
define a function with 23 parameters?

_**Pica**_: Let's see
```kotlin
fun f23(p1:Int,.., p23:Int) = ""
```

a call to `::f23` results in a runtime exception:
```kotlin
java.lang.NoClassDefFoundError: kotlin/Function23      
```
This is in Kotlin v. 1.2.60 - there is a development goal to [_Get rid of 23 hardwired physical function classes_](https://github.com/JetBrains/kotlin/blob/1.3-M2/spec-docs/function-types.md).

_**Elster**_: hmm... ok, this nice and all but what is the point of this exercise?

_**Pica**_: It allows someone who is coming from OO background to match functional 
idioms in Kotlin to something more familiar. First of all the notation `(T1,T2,..,Tn) -> R`
maps directly to the functional (SAM) interface `Function[n]<T1,T2,..,Tn,R>`. Some more examples:

Currying and partial application: 

{{<highlight kotlin>}}
    // Kotlin idiomatic
    fun add(a: Int): (Int) -> Int = { b -> a + b }

    val add1 = add(1)
    println ( add1(2))    // 3


    // Using class based implementation
    object Add {
        fun add(a: Int): Function1<Int, Int> {
            return object: Function1<Int, Int> {
                override fun invoke(b: Int): Int = a + b
            }
        }
    }

    val add1 = Add.add(1)
    add1(2)        // 3
{{</highlight>}}

Accumulator function: 

{{<highlight kotlin>}}
    // Kotlin idiomatic
    fun a(n: Int): (d: Int) -> Int {
        var accumulator = n
        return { x -> accumulator += x; accumulator }
    }

    val a100 = a(100)
    
    a100(5)    // 105
    a100(10)   // 115
    a(1)(5)    // 6

    // Using class based implementation
    object A {
        var accumulator :Int = 0

        fun a(n : Int) : (Int) -> Int {
            accumulator = n

            return object: (Int) -> Int {
                override fun invoke(n: Int): Int {
                    accumulator += n
                    return accumulator;
                }
            }
        }
    }

    val A100 = A.a(100)

    A100(5)   // 105
    A100(10)  // 115
    A.a(1)(5) // 6
{{</highlight>}}

