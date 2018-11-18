---
title: "The forEach API"
date: 2018-11-17T19:00:01+01:00
tags: ["kotlin", "collections", "api"]
---

![](/img/kotlin-api.png)

After one time too many stumbling over a forgotten/unknown function in Kotlin's "collection" API, I decided to take stock 
of what's available.  

**TLDR** - That API is pretty large.
  

<!--more-->

</p>
#### Definitions

Some definitions are in order. I put "collection" in double quotes because from my practical perspective a collection is 
pretty much any generic container I can `forEach` over (`CharSequence` is excluded being character specific). Towards 
the end of this post there is a more solid justification for using `forEach` as an umbrella name for "collections".  
 
In Kotlin the interfaces that fit the description are:

* `Collection` - resides in `kotlin.collections` package.
* `Array` - Array's are not `Collection`s. They reside in the `kotlin` package
* `Iterable` - resides in the `kotlin.collections` package, Supertype of `Collection`.
* `Sequence` - resides in the `kotlin.sequences`package.
* `Map` - As in Java - Map stands alone, it resides in the `kotlin.collections` package but is not a `Collection`. 

To size the API, I decided to look at the extension functions defined for the above interfaces, to enumerate the
extension functions I took the (somewhat hacky) approach of scraping the online API documentation.  


The code:

 
{{< highlight kotlin >}}
import org.jsoup.Jsoup

val docRoot = "https://kotlinlang.org/api/latest/jvm/stdlib"

val docUrls = mapOf(
        "array"      to "$docRoot/kotlin/-array/",
        "sequence"   to "$docRoot/kotlin.sequences/-sequence/index.html",
        "iterable"   to "$docRoot/kotlin.collections/-iterable/index.html",
        "collection" to "$docRoot/kotlin.collections/-collection/index.html",
        "map"        to "$docRoot/kotlin.collections/-map/index.html"
)


fun extensionFunctions(url: String): Set<String> {
    return Jsoup.connect(url).get()
            .selectFirst("h3#extension-functions ~ div.api-declarations-list")
            .select("h4 > a")
            .map { e -> e.ownText() }
            .toSet()
}

val funMap: Map<String, Set<String>> = docUrls.mapValues { extensionFunctions(it.value) }
{{</highlight>}}

----

#### Results


  Interface         | Extension Function #
  -------------     | -------------
  Collection        | 115
  Array             | 142
  Iterable          | 107
  Sequence          | 105
  Map               | 47
  **total unique**  | **173**

Here is a visualization and a breakdown courtesy of [University of Gent](http://bioinformatics.psb.ugent.be/webtools/Venn/):
![API venn diagram](/img/kotlin-collection-api-venn.png)

The table below indicates which methods are in each intersection or are unique to a certain interface. For example out 
of 105 `Sequence` extension functions, only two are unique one of them being `ifEmpty`. 

  Names             | Total         | Elements
  -------------     | ------------- | -------------
array collection iterable map sequence | 25 | `mapNotNullTo flatMapTo count mapTo all asSequence contains toMap asIterable toList filterTo maxBy map filterNotTo forEach flatMap none filterNot filter any minWith plus maxWith mapNotNull minBy`
array collection iterable sequence     | 62 | `sumByDouble mapIndexedTo groupBy flatten toMutableList reduce groupingBy last indexOfLast elementAt sortedByDescending requireNoNulls distinctBy toHashSet fold zip dropWhile filterIsInstanceTo firstOrNull lastIndexOf joinTo toSortedSet foldIndexed elementAtOrNull joinToString elementAtOrElse unzip take indexOfFirst distinct toSet mapIndexedNotNull mapIndexed withIndex partition drop find mapIndexedNotNullTo groupByTo forEachIndexed filterIndexed singleOrNull filterNotNull filterIsInstance associateBy associateByTo lastOrNull single associate indexOf toMutableSet reduceIndexed toCollection takeWhile findLast sortedWith sortedBy filterIndexedTo first associateTo sumBy filterNotNullTo`
collection iterable map sequence	   | 2	| `onEach minus`
array collection iterable              | 4  | `union subtract reversed intersect`
array iterable sequence	               | 6  | `average sortedDescending sorted sum max min`
array collection map                   | 2  | `isNotEmpty isNullOrEmpty`
collection iterable sequence           | 7  | `associateWithTo plusElement windowed chunked zipWithNext associateWith minusElement`
collection map sequence                | 1  | `orEmpty`
array collection                       | 9  | `toByteArray toShortArray toCharArray toLongArray toFloatArray random toDoubleArray toIntArray toBooleanArray`
array map                              | 1  | `getOrElse`
collection iterable                    | 1  | `shuffled`
array                                  | 33 | `foldRightIndexed binarySearch component3 subarrayContentToString reversedArray toCValues sort getOrNull slice sortByDescending foldRight sortWith component4 fill isArrayOf takeLast sortBy reduceRightIndexed component5 sortedArrayWith sliceArray sortedArray component2 takeLastWhile sortDescending sortedArrayDescending dropLast component1 reduceRight dropLastWhile isEmpty reverse toCStringArray`
collection                             | 2  | `containsAll waitForMultipleFutures`
map                                    | 16 | `mapKeys filterValues mapValuesTo getOrDefault iterator toMutableMap withDefault filterKeys mapKeysTo mapValues get toProperties containsValue getValue containsKey toSortedMap`
sequence                               | 2  | `ifEmpty constrainOnce`

The first row lists the extension functions that belong to all the interfaces and the reason I take `forEach` to be a 
"defining" collection function.  

#### Conclusions

* At 173 functions, it is a pretty large API. True, I may never need some of the functions (looking at you `toCValues`)
but they are there in the documentation and auto-completion competing for my attention.
* The package structure - there probably is a way to rationalize it, but to me it looks confusing.
* The bulk comparison approach is a different way to look at APIs and points at further investigations. For example `Sequence`
and `Iterable` are almost identical but `Sequence` has `orEmpty` and `ifEmpty` functions which are not present in `Iterable` -
 why not?   
* The `Array` and `Collection` APIs have a naming convention regarding sorting: functions named `sortXXX` (e.g. `sortBy`) 
do the sorting **in-place** while functions named `sortedXXX` (e.g. `sortedBy`) produce a new  collection. 
        