# HexSpeak in Clojure, Python and other languages

## What is HexSpeak?

"HexSpeak" refers to the use of hex nibbles to create words.
For example:

- Did someone overwrote my magic sentinel value? (`0xDEADBEEF`)
- That board's register should return `0xDEADC0DE` by default.
- Someone `0x0DEFACED` my code!
- etc.

Phrases like these pop up as magic constants in various places - markers
in memory, sentinel values in registers and custom buses, etc.

But... how can we figure out all possible hexspeak phrases of a
target length and count them all?

## What! Why would you do this? Are you crazy?

Oh, don't get mad - I just wanted to play with Clojure :-)

I also did some speed benchmarks... Compared to execution with CPython,
the Clojure version of the same algorithm runs 2.5x faster (when
executed in a warmed-up JVM).

But since Clojure uses the JVM's JIT compilation, the proper comparison is
with PyPy - which amazingly, does a better job ; it runs 4.6x faster
than CPython (almost 2x faster than Clojure).

**Update:** Added use of [ShedSkin](https://github.com/shedskin/shedskin).
Since I got interested in speed results, I tried using ShedSkin;
which in the end runs 40% faster than PyPy, or put simply, executes
the same Python code 7x times faster than CPython (3x faster than Clojure).
Very impressive.

**Update:** But this experiment wasn't really about speed - it was about my desire
to play with Lisps again. So I added an [implementation](contrib/HyLang/hexspeak.hy)
in [a very Pythonic Lisp (HyLang)](https://github.com/hylang). Hy runs
my code 3x slower than CPython, but at this point I don't care; it was
so much fun, playing with it :-) And since there's a hy2py converter,
it also allowed me to execute the result under PyPy.

The table below shows the results I get in my laptop from executing my
implementations (using all the languages and all the tools). They all
return the same number (3020796) of different phrases of length 14,
that can be formed from the 'ABCDEF' hex nibbles:

| Language/Tool   | Execution time in ms, to count HexSpeak(14) |
| --------------- | ------------------------------------------- |
| C++             |                                    34.96600 |
| Java            |                                   104.00000 |
| Python/ShedSkin |                                   357.70300 |
| Python/PyPy     |                                   520.08700 |
| Clojure         |                                   911.20476 |
| Python/HyLang   |                                  1467.77487 |
| Python/CPython  |                                  2432.77812 |

## Step 1 - collect the candidate words

The execution begins by filtering `contrib/words` with a regexp,
to find the candidate `good-words` - those that is, that can be
formed from the selected hex nibbles. They are then arranged
in a way that allows quick lookups of words for a specific length:

Python:

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


Clojure: *(refactored the logic in two functions - one filters
the words, another groups them via `group-by` based on length: )*

    (defn good-words [rdr letters]
      (let [matcher (re-pattern (str "^[" letters "]*$"))
            forbidden #{"aaa" "aba" "abc"}]
        (doall (->> (line-seq rdr)
                    (filter #(and (> (.length ^String %) 2)
                                  (not (contains? forbidden %))
                                  (re-matches matcher %)
                                  ))))))

    (defn get-words-per-length [letters]
      (let [input-file "/usr/share/dict/words"
            candidates (with-open [rdr (clojure.java.io/reader input-file)]
                         (good-words rdr letters))
            in-map-form (group-by #(.length ^String %)
                                  (concat candidates ["a"]))
            max-length (inc (reduce max (keys in-map-form)))]
        (into [] (map #(get in-map-form % []) (range max-length)))))

Testing the Clojure code - showing 3- and 4-letter candidate words:

    (get (get-words-per-length "abcdef") 3)
    ==> ["ace" "add" "baa" "bad" "bed" "bee" "cab" "cad" "dab" "dad" "deb"
         "def" "ebb" "eff" "fab" "fad" "fed" "fee"]

    (get (get-words-per-length "abcdef") 4)
    ==> ["abbe" "abed" "aced" "babe" "bade" "bead" "beef" "cafe" "caff" "ceca"
     "cede" "dace" "dded" "dead" "deaf" "deed" "face" "fade" "faff" "feed"]

Now that the candidate words are there, it's time to assemble them recursively.

## Step 2: Assemble the candidates

Python: *(to avoid using a global counter, I just mutate the first
element of a list. In the initial version of the code, I was adding the phrases
to this list so the caller of `solve` could print them - but this
benchmark just counts them: )*

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

Clojure: *a `volatile!` is faster than an `atom` (for the counter)*

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

Both of the languages allow for equally succinct implementations.

## Step 3: Speed!

I added a `bench` rule in my Makefile, that measures 10 runs of `solve`
for 14-character long HexSpeak phrases. I used `time.time()` in Python,
and Clojure's `time` to do the measurements. I took the minimum of the
10 runs, to avoid (a) the JVM's startup cost and (b) to also take advantage
of the 'warm-up' of the HotSpot technology *(the first couple of `solve`
runs are much slower than the rest, since the JVM figures out the best
places to JIT at run-time)*.

**UPDATE, two days later**: I also added a Java implementation to the mix.
Unexpectedly, it runs much faster than Clojure (9x) - apparently recursively
calling a function millions of times is a pattern that is optimized a lot
better in Java than it is in Clojure.

**UPDATE, four days later**: I also added a C++ implementation to the mix;
and since I could play with the actual string data there, I switched
`used` to using them instead of strings... In CS parlance, I *interned*
the strings - which made C++ 3 times faster than Java. To be objective,
though, C++ was also the only language where I had segfaults while coding.

*(easy, correct, fast - pick two)* :-)

**UPDATE, a month later**: I also added a [HyLang](https://github.com/hylang)
implementation to the mix. HyLang is a Lisp that offers Clojure syntax on top
of seemless interoperability with Python's standard library; that is,
a Lisp where I already knew the standard library! It compiles to Python AST
and serializes the output as Python bytecode - so I executed it with PyPy
to give it a chance in the benchmarking. It ended up half-way between CPython
and Clojure. It was also the most fun I've had in years :-)


Final speed results in my latop:


    $ make bench
    ...
    Benchmarking C++ (best out of 10 executions)...
                Min: 34.96600


    Benchmarking Java (best out of 10 executions)...
                Min: 104.00000


    Benchmarking ShedSkin (best out of 10 executions)...
                Min: 357.70300


    Benchmarking PyPy (best out of 10 executions)...
                Min: 520.08700


    Benchmarking Clojure (best out of 10 executions)...
                Min: 911.20476


    Benchmarking Hy via PyPy (best out of 10 executions)...
                Min: 1467.77487


    Benchmarking Python (best out of 10 executions)...
                Min: 2432.77812


Note that this is the exact same algorithm in all cases - a plain recursion
visiting the *word space* of HexSpeak, in exactly the same order.

These results more or less match my expectations when I started this
Clojure experiment... Clojure is much faster than Python, but it's also
(much!) slower than plain Java. PyPy's performance surprised me (in a
good way) - and of course, C++ speed is on a class of its own...
*(with the code being a mutable mayhem of interned pointers to chars)* :-)

## JMH and Criterium

Benchmarking under the JVM can be perilous - the established wisdom
is that for Java you use
[JMH](https://github.com/ttsiodras/HexSpeak/tree/master/contrib/HexSpeak-bench.java.with.JMH/benchmarks)
and for Clojure you use
[Criterium](https://github.com/ttsiodras/HexSpeak/blob/criterium/src/thanassis/hexspeak.clj#L82).

As you can see in the links to my code above, I used both of them. For micro-benchmarks
these tools may indeed provide different results - but in my case, there was no
discernible difference in the results. Note that I am running the algorithm
10 times and taking the minimal time ; and both tools provided very similar results
to my naive measurements with Clojure's `time` and Java's `System.nanotime`.

## BoxPlot

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
with [this immutable addition in Clojure](https://github.com/ttsiodras/HexSpeak/blob/master/src/thanassis/hexspeak.clj#L50).

All in all, this was fun - and quite educational. Many thanks to the people
that provided feedback in [the discussion at Reddit/Clojure](https://www.reddit.com/r/Clojure/comments/4l28go/pitting_clojure_against_python_in_hexspeak/).
