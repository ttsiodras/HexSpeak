# HexSpeak in Clojure, Python and other languages

## What is HexSpeak?

"HexSpeak" refers to the use of hex nibbles to create words.
For example:

- Did someone modify my magic sentinel value? (`0xDEADBEEF`)
- That board's register should return `0xDEADC0DE` by default.
- Someone `0x0DEFACED` my code!
- etc.

Phrases like these pop up as magic constants in various places - markers
in memory, sentinel values in registers and custom buses, etc.

But... how can we figure out all possible hexspeak phrases of a
target length and count them all?

## What! Why would you do this? Are you crazy?

Oh, don't get mad - I just wanted to play with Clojure :-)
And Scala. And HyLang. And C++.

Mostly, I wanted to play :-)

I also did some speed benchmarks.

But let's look at the code first:


## Step 1 - collect the candidate words

The execution begins by filtering `contrib/words` with a regexp,
to find the candidate `good-words` - those that is, that can be
formed from the selected hex nibbles. They are then arranged
in a way that allows quick lookups of words for a specific length:

Python:

```python
def get_words_per_length(dictionaryFile, letters):
    words = [[] for _ in range(128)]
    m = re.compile(r'^[' + letters + ']*$')
    for word in open(dictionaryFile):
        word = word.strip()
        if len(word) > 2 and m.match(word):
            if word in ['aaa', 'aba', 'abc']:
                continue
            if word not in words[len(word)]:
                words[len(word)].append(word)
    words[1] = ['a']
    return words
```

Clojure: *(refactored the logic in two functions - one filters
the words, another groups them via `group-by` based on length: )*

```clojure
(defn good-words [rdr letters]
  (let [matcher (re-pattern (str "^[" letters "]*$"))
        forbidden #{"aaa" "aba" "abc"}]
    (doall (->> (line-seq rdr)
                (filter #(and (> (.length ^String %) 2)
                              (re-matches matcher %)
                              (not (contains? forbidden %))))))))

(defn get-words-per-length [dictionary-file letters]
  (let [candidates (with-open [rdr (clojure.java.io/reader dictionary-file)]
                     (good-words rdr letters))]
    (group-by #(.length ^String %) (concat candidates ["a"]))))
```

Testing the Clojure code from the REPL - showing 3- and 4-letter candidate words:

    (get (get-words-per-length "contrib/words" "abcdef") 3)
    ==> ["ace" "add" "baa" "bad" "bed" "bee" "cab" "cad" "dab" "dad" "deb"
         "def" "ebb" "eff" "fab" "fad" "fed" "fee"]

    (get (get-words-per-length "abcdef") 4)
    ==> ["abbe" "abed" "aced" "babe" "bade" "bead" "beef" "cafe" "caff" "ceca"
     "cede" "dace" "dded" "dead" "deaf" "deed" "face" "fade" "faff" "feed"]

Scala: *(Succinct, type-safe... and fast! see below)*

```scala
def get_words_per_length(dictionaryFile: String, letters: String) = {
  val p = new Regex("^[" ++ letters ++ "]*$")
  val forbidden = List("aaa", "aba", "abc")
  ("a" :: Source.fromFile(dictionaryFile).getLines().filter(
    l => 
      l.length > 2 &&
      p.findFirstIn(l).nonEmpty &&
      !forbidden.contains(l)).toList).
  groupBy(_.length)
}
```

Now that the candidate words are there, it's time to assemble them recursively.

## Step 2: Assemble the candidates

Python: *(to avoid using a global counter, I just mutate the first
element of a list. In the initial version of the code, I was adding the phrases
to this list so the caller of `solve` could print them - but this
benchmark just counts them: )*

```python
def solve_recursive_count(words, currentLen, used, targetLength, cnt):
    for i in range(1, targetLength - currentLen + 1):
        for word in words.get(i, []):
            if word in used:
                continue
            if i != targetLength - currentLen:
                solve_recursive_count(
                    words, currentLen + i, used + [word], targetLength, cnt)
            else:
                cnt[0] += 1
cnt = [0]
solve_recursive_count(words, 0, [], targetLength, cnt)
print "Total:", cnt[0]
```

Clojure: *a `volatile!` is faster than an `atom` (for the counter)*

```clojure
(defn solve
  [words-per-length target-length phrase-len used-words counter]
  (dotimes [i (- target-length phrase-len)]
    (doseq [w (get words-per-length (inc i) [])]
      (if (not (contains? used-words w))
        (if (= target-length (+ i phrase-len 1))
          (vswap! counter inc) ;faster than swap! and atom
          (solve words-per-length target-length (+ phrase-len (inc i))
                 (conj used-words w) counter))))))
(let [counter (volatile! 0) ; faster than atom
      words-per-length (get-words-per-length "abcdef")]
  (do
    (time (solve words-per-length phrase-length 0 #{} counter))
    (printf "Total: %d\n" @counter)))
```

Scala:

```scala
def solve_recursive_count(words:Map[Int, List[String]], currentLen:Int,
                          used:List[String], targetLength:Int):Unit = {
    for (i <- 1 to (targetLength - currentLen))
      for(word <- words.getOrElse(i, List()))
        if (!used.contains(word))
          if (i != targetLength - currentLen)
            solve_recursive_count(words, currentLen + i, word :: used, targetLength)
          else
            cnt += 1
  }

val words = get_words_per_length("../words", "abcdef")
cnt = 0
val s = System.currentTimeMillis
solve_recursive_count(words, 0, List(), 14)
println(cnt + " in " + (System.currentTimeMillis - s) + " ms")
```

All three languages allow for equally succinct implementations.

## Step 3: Speed!

The table below shows the results I get in my laptop from executing my
implementations (using all the languages and all the tools). They all
return the same number (3020796) of different phrases of length 14,
that can be formed from the 'ABCDEF' hex nibbles:

| Language/Tool      | Execution time in ms, to count HexSpeak(14) |
| ------------------ | ------------------------------------------- |
| C++                |                                    34.96600 |
| Java               |                                   104.00000 |
| Scala              |                                   122.00000 |
| Python/ShedSkin    |                                   357.70300 |
| Python/PyPy        |                                   520.08700 |
| Clojure            |                                   911.20476 |
| Python/HyLang/Pypy |                                  1467.77487 |
| Python/CPython     |                                  2432.77812 |

![Tukey boxplot of performance for the fast ones](https://raw.githubusercontent.com/ttsiodras/HexSpeak/master/contrib/boxplot.png "Tukey boxplot of performance for the fast ones")

Note that this is the exact same algorithm in all cases - a plain recursion
visiting the *word space* of HexSpeak, in exactly the same order.

### Analysis

#### Clojure/PyPy

Compared to execution with CPython, the Clojure implementation of the
same algorithm runs 2.5x faster (when executed in a warmed-up JVM).
But since Clojure uses the JVM's JIT compilation, the proper comparison
is with [PyPy](http://pypy.org/) - which amazingly, does a better job ;
it runs 4.7x faster than CPython (almost 2x faster than Clojure).

#### Python/Shedskin

Since I got interested in speed, I then tried [ShedSkin](https://github.com/shedskin/shedskin),
which converts the Python code to C++. It executed 40% faster than PyPy,
or put simply, makes the same Python code 7x times faster than CPython
(that is, 3x faster than Clojure!)

Very impressive result.

#### HyLang

But this experiment wasn't really about speed - it was about my desire
to play with Lisps again. So I added an [implementation](contrib/HyLang/hexspeak.hy)
in [a very Pythonic Lisp (HyLang)](https://github.com/hylang). *Hy* run
the code 3x slower than CPython - but then again, I can't remember the
last time I had so much fun, playing with a language :-) You see, the most
troublesome part when fooling around with a language is learning the new
standard library - but Hy uses Python's... so if you speak Python and you
know Lisp syntax, you "instantly" speak Hy! :-)

Since it came with hy2py (a .hy to .py converter), it also allowed me to
execute the result under PyPy - which brought performance decently close
to Clojure's (50% slower).

#### C++

I also added a C++ implementation to the mix; and since I could
play with the actual string data there, I switched the `used` container
to storing the pointers instead of the strings... In CS parlance, I *interned*
the strings - which made C++ 3 times faster than Java. To be objective,
though, C++ was also the only language where I had segfaults while coding.

*(easy, correct, fast - pick two)* :-)

#### Java

Don't ask - I was just curious. And it turns out that it runs an order of
magnitude faster than Clojure (9x) - apparently recursively calling a
function millions of times is a pattern that is optimized a heck of a lot
better in Java than it is in Clojure.

#### Scala

Ah, the siren song of the ML family... Once you meet it in any of its forms
(OCaml, Haskell, F#, Scala), forever it will dominate your destiny...
Succinct, type-safe... and fast, too - just as fast as Java. Of all the
`get_words_per_length` implementations, I like Scala's form the most;
even though I am a complete newb and have almost never used this language
for anything. I also loved that I could do this coding in the REPL,
figuring out the APIs on the fly. Best of all worlds? Maybe...

#### How did you benchmark?

I added a `bench` rule in my Makefile, that measures 10 runs of `solve`
for 14-character long HexSpeak phrases. I used `time.time()` in Python,
and Clojure's `time` to do the measurements *(but see also section below
about JMH and Criterium)*. I took the minimum of the 10 runs,
to avoid (a) the JVM's startup cost and (b) to also take advantage
of the 'warm-up' of the HotSpot technology *(the first couple of `solve`
runs are much slower than the rest, since the JVM figures out the best
places to JIT at run-time)*.

#### JMH and Criterium

Benchmarking under the JVM can be perilous - the established wisdom
is that for Java you use
[JMH](https://github.com/ttsiodras/HexSpeak/tree/master/contrib/HexSpeak-bench.java.with.JMH/benchmarks)
and for Clojure you use
[Criterium](https://github.com/ttsiodras/HexSpeak/blob/criterium/src/thanassis/hexspeak.clj#L82).

As you can see in the links to my code above, I tried both of them.
For micro-benchmarks these tools may indeed provide results that are much
different that plain old Clojure `time` or Java's `System.nanotime` - but
in this case, there was no discernible difference between the "advanced"
timing results from JMH and Criterium, and those of the "simple" methods.
*Keep in mind that in the "simple" methods the algorithm is run 10 times
and the minimum time is taken.*

### Thoughts on speed

These results more or less match my expectations when I started this
Clojure experiment... Clojure is faster than CPython, but it's also
(much!) slower than plain Java. PyPy's performance surprised me (in a
good way), Scala is awesome (loved both the syntax and the speed!),
and finally, of course, C++ speed puts it on a class of its own... :-)

### BoxPlot

We can see the spread of the measurements by creating a Tukey boxplot...

    $ make boxplot

![Tukey boxplot of performance for the fast ones](https://raw.githubusercontent.com/ttsiodras/HexSpeak/master/contrib/boxplot.png "Tukey boxplot of performance for the fast ones")

...where it becomes clear (from the outliers) that even though the JVM starts at approximately
the same speed as PyPy, HotSpot quickly kicks-in and moves performance much closer to C++ levels.

## Concluding thoughts

I liked playing with Clojure, and loved playing with HyLang (since I didn't have
to lookup any standard library - I already know Python's). To be honest, I have
[a soft spot for all Lisps](https://www.thanassis.space/score4.html#lisp)
so it was interesting to fiddle with them again. And even though this benchmark
reminded me that *there's no free lunch* (i.e. Clojure is slower than Java,
HyLang is slower than PyPy (and even more so for ShedSkin), still, I enjoyed
playing with Lisp syntax again. Didn't do any macros this time :-)

Clojure in particular nudges towards an immutable way of working with the data,
which shields your code from tons of bugs (e.g. contrast
[this mutation in Java](https://github.com/ttsiodras/HexSpeak/blob/master/contrib/hexspeak.java#L59)
with [this immutable addition in Clojure](https://github.com/ttsiodras/HexSpeak/blob/master/src/thanassis/hexspeak.clj#L47).

Then again, so does Scala. And the additional static type safety that it brings with it,
is arguably a huge asset in large codebases and refactorings... Enough so that the
Python world is now playing catchup with mypy, and Clojure is trying to achieve
similar results with `clojure.spec` (at run-time, though). 

Anyway... all in all, this was fun - and quite educational. Many thanks to the people
that provided feedback in [the discussion at Reddit/Clojure](https://www.reddit.com/r/Clojure/comments/4l28go/pitting_clojure_against_python_in_hexspeak/).
