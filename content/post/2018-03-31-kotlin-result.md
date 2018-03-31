---
title: "Kotlin Result"
date: 2018-03-31T18:17:09+01:00
tags: ["kotlin"]
---

![](/img/kotlin.png)

Some languages provide a facility to return an error from a call to method/function, along with the actual result value.
This allows (or forces) the programmer to take into account potential runtime errors.

Something similar can be done in Kotlin.

<!--more-->

>
> Sources are [here](https://gist.github.com/sorokod/1d45d03d8e25700873edf8c1e4ca8b8c).
>



### Ok - Err

In Rust, functions may return a `result` type that can be handled with `match`:
{{< highlight rust >}}
enum Result<T, E> {
   Ok(T),
   Err(E),
}
...

match a_result {
    Ok(v) => ..., // deal with the value
    Err(e) => ...,// handle error
}
{{</ highlight>}}

Kotlin's take on enums are [sealed classes](https://kotlinlang.org/docs/reference/sealed-classes.html) and the definition
looks quite similar:
{{< highlight kotlin >}}
package result

import result.Result.Err
import result.Result.Ok

sealed class Result<out T> {
    data class Ok<out T>(val value: T): Result<T>()
    data class Err(val exception: Exception, val msg): Result<Nothing>()
}
{{</ highlight>}}
</p>

For better ergonomics, we can also provide default values in `Err` constructor:

{{< highlight kotlin >}}
data class Err(val exception: Exception = RuntimeException(),val msg: String = ""): Result<Nothing>()
{{</ highlight>}}


With these definitions in place we can take this code for test drive:

{{< highlight kotlin >}}
fun query(id: Int): Result<String> = when (id) {
    1 -> Ok("a result")
    else -> Err(msg = "something went wrong...")
}

val result = query(...)

when (result) {
    is Ok -> println("Got ${result.value}")
    is Err -> {
        val (exe, msg) = result
        println("Exception = $exe , msg = $msg")
    }
}
{{</ highlight>}}

### None - Some - Err

By using `Ok` to indicate that no error has occurred, we are not well equipped to deal with the situations that a value is
not available. This is often indicated by `null` and Kotlin has [language-level support](https://kotlinlang.org/docs/reference/null-safety.html)
to deal with this case.

In the context of this post, it is more natural to incorporate the lack of value into the result
object. We replace `Ok` with `None` and `Some`:

{{< highlight kotlin >}}
package optionalresult

import optionalresult.OptionalResult.*

sealed class OptionalResult<out T> {
    object None : OptionalResult<Nothing>()
    data class Some<out T>(val value: T) : OptionalResult<T>()
    data class Err(val exception: Exception = RuntimeException(), val msg: String = "") : OptionalResult<Nothing>()
}
{{</ highlight>}}

In this case the test drive looks like this:
{{< highlight kotlin >}}
fun query(id: Int): OptionalResult<String> = when (id) {
    0 -> None
    1 -> Some("a result")
    else -> Err(msg = "something went wrong...")
}

val result = query(...)

when (result) {
    is None -> println("not found")
    is Some -> println("Got ${result.value}")
    is Err -> {
        val (exe, msg) = result
        println("Exception = $exe , msg = $msg")
    }
}
{{</ highlight>}}

Still following [the Rust approach](https://doc.rust-lang.org/std/option/enum.Option.html#method.expect) we can add
an `expect()` method to `OptionalResult`. This may be useful if we want to fail without much ceremony when we are expecting
a result value to be available (in a unit test for example).

{{< highlight kotlin >}}
sealed class OptionalResult<out T> {
    object None : OptionalResult<Nothing>()
    data class Some<out T>(val value: T) : OptionalResult<T>()
    data class Err(val exception: Exception = RuntimeException(), val msg: String = "") : OptionalResult<Nothing>()

    fun expect(errorMsg: String): T = when (this) {
        is None -> throw IllegalStateException(errorMsg)
        is Err -> throw IllegalStateException(errorMsg)
        is Some -> this.value
    }
}


lateinit var v: String

v =  None.expect("expected: a result") // IllegalStateException: expected a result

v =  Err().expect("expected: a result") // IllegalStateException: expected a result

v = Some("a result").expect("expected: a result") // v has the value "a result"

{{</ highlight>}}

