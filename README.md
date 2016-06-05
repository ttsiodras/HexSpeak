# Introduction - HexSpeak in Clojure and Python

**(Executive summary: An experiment I did while playing with Clojure...
Results: compared to CPython, the same algorithm runs 2.5x faster
when written in Clojure and executed in a warmed-up JVM ...but
PyPy takes the gold medal: it runs it 6x faster!)**

## What is HexSpeak?

- Did I remember to remove my dead code? (`0xDEADC0DE`).
- Have you seen my dead beef? (`0xDEADBEEF`)
- Someone `0x0DEFACED` my code!

...etc. Phrases like these pop up as magic constants in various 
places - markers in memory, in custom buses, etc.

But... how can we figure out all possible hexspeak phrases of a
target length and count them?

[![alt](https://asciinema.org/a/9trefb2q1f3zzpyfnj3u6bpkc.png)](https://asciinema.org/a/9trefb2q1f3zzpyfnj3u6bpkc)

## Step 1 - collect the candidate words

We filter `/usr/share/dict/words` with a regexp first,
to find the candidate `good-words` - and then arrange them
so we can quickly get to those of a specific length:

Python:

    words = {}
    letters = "abcdef"
    m = re.compile(r'^[' + letters + ']*$')
    for word in open('/usr/share/dict/words'):
        word = word.strip()
        if len(word) > 2 and m.match(word):
            if word in ['aaa', 'aba', 'abc']:
                continue
            if word not in words.get(len(word), []):
                words.setdefault(len(word), []).append(word)
    words[1] = ['a']

Clojure: *(refactored logic in two functions - one filters
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

OK, we have the candidates... time to assemble them recursively!

## Step 2: Assemble the candidates

Python: *(to avoid using a global counter, I just mutate the first 
element of a list. In the initial version of the code, I was adding the phrases
to this list so the caller of `solve` could print them - but this 
benchmark just counts them: )*

    def solve_recursive_count(words, currentLen, used, targetLength, cnt):
        for i in xrange(1, targetLength - currentLen + 1):
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

Clojure: *(using a `volatile!` - faster than `atom` - for the counter)*

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

I then added a `bench` rule in my Makefile, that measures 10 runs of `solve`
for 14-character long HexSpeak phrases. I used `time.time()` in Python,
and Clojure's `time` to do the measurements - and took the minimum of the
10 runs to avoid the JVM's startup cost and also take advantage of the warm-up
of the HotSpot technology (the first couple of `solve` runs are much slower
than the rest, since the JVM figures out the best places to JIT at run-time). 

**UPDATE, two days later**: I also added a Java implementation to the mix.
Unexpectedly, much faster than Clojure - apparently recursively calling
a function millions of times is a pattern that is optimized a lot better
in Java than it is in Clojure.

**UPDATE, four days later**: I also added a C++ implementation to the mix;
and since I could play with the actual string data there, I switched
`used` to using them instead of strings... In CS parlance, I *interned*
the strings - which made C++ 3 times faster than Java.

Of course it was also the only language where I had segfaults as I was coding
*(easy, correct, fast - pick two)* :-)

Results in my laptop:

    $ make bench
    Benchmarking Python (best out of 10 executions)...
                Min: 2432.77812
    
    Benchmarking Clojure (best out of 10 executions)...
                Min: 935.23521
    
    Benchmarking PyPy (best out of 10 executions)...
                Min: 382.45010
    
    Benchmarking Java (best out of 10 executions)...
                Min: 103.00000

    Benchmarking C++ (best out of 10 executions)...
                Min: 34.28970

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
[https://github.com/ttsiodras/HexSpeak/tree/master/contrib/HexSpeak-bench.java.with.JMH/benchmarks](JMH)
and for Clojure you use 
[https://github.com/ttsiodras/HexSpeak/blob/criterium/src/thanassis/hexspeak.clj#L82](Criterium).

As you can see in the links to my code above, I used both of them. For micro-benchmarks
these tools may indeed provide different results - but in my case, there was no 
discernible difference in the results. Note that I am running the algorithm
10 times and taking the minimal time ; and both tools provided very similar results
to my naive measurements with Clojure's `time` and Java's `System.nanotime`.

## BoxPlot

We can see the spread of the measurements by creating a Tukey boxplot...

    $ make boxplot

![Tukey boxplot of performance for PyPy, Java and C++](https://raw.githubusercontent.com/ttsiodras/HexSpeak/master/contrib/boxplot.png "Tukey boxplot of performance for PyPy, Java and C++")

...where it becomes clear that even though the JVM starts at approximately
the same speed as PyPy, HotSpot quickly kicks-in and moves performance
much closer to C++ levels.

## Concluding thoughts

I liked playing with Clojure. I have [a soft spot for Lisps](https://www.thanassis.space/score4.html#lisp)
so it was interesting to fiddle with one again. And even though this benchmark
reminded me that *there's no such thing as a free lunch* (i.e. Clojure is slower than Java),
Clojure's immutable way of working shields your code from tons of bugs (e.g. contrast
[this mutation in Java](https://github.com/ttsiodras/HexSpeak/blob/master/contrib/hexspeak.java#L59)
with [this immutable addition in Clojure](https://github.com/ttsiodras/HexSpeak/blob/master/src/thanassis/hexspeak.clj#L50).

All in all, this was fun - and quite educational. Many thanks to the people
that provided feedback in [the discussion at Reddit/Clojure](https://www.reddit.com/r/Clojure/comments/4l28go/pitting_clojure_against_python_in_hexspeak/).
