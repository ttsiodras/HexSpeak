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

But... how can we figure out all possible hexspeak phrases?

## Step 1 - collect the candidate words

Well, filter /usr/share/dict/words with a regexp first,
to find the candidate `good-words`, then place them
in a vector:

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

Clojure:

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
    ["abbe" "abed" "aced" "babe" "bade" "bead" "beef" "cafe" "caff" "ceca"
     "cede" "dace" "dded" "dead" "deaf" "deed" "face" "fade" "faff" "feed"]

OK, we have the candidates... time to assemble them!

## Step 2: Assemble the candidates

Python:

    def solve_recursive_count(words, currentLen, used, targetLength, cnt):
        for i in xrange(1, targetLength - currentLen + 1):
            for word in words.get(i, []):
                if word in used:
                    continue
                if i != targetLength - currentLen:
                    solve_recursive_count(
                        words, currentLen + i, used + [word], targetLength, cnt)
                else:
                    # print currentPhrase, word
                    cnt[0] += 1

    cnt = [0]
    solve_recursive_count(words, 0, [], targetLength, cnt)
    print "Total:", cnt[0]

Clojure:

    (defn solve
      [words-per-length target-length phrase-len used-words counter]
      (dotimes [i (- target-length phrase-len)]
        (doseq [w (get words-per-length (inc i) [])]
          (if (not (contains? used-words w))
            (if (= target-length (+ i phrase-len 1))
              (swap! counter inc)
              (solve words-per-length target-length (+ phrase-len (inc i)) (conj used-words w) counter))))))
    (let [counter (atom 0)
          words-per-length (get-words-per-length "abcdef")]
      (do
        (time (solve words-per-length phrase-length 0 #{} counter))
        (printf "Total: %d\n" @counter)))

Both of the implementations are equally succinct.

## Step 3: Speed!

I added a `bench` rule in my Makefile, that measures 10 runs of `solve`
for 14-character long HexSpeak phrases. I used `time.time()` in Python,
and Clojure's `time` - to avoid the JVM's startup cost and also warm-up
the HotSpot technology (the first couple of runs are much slower than
the rest). 

**UPDATE, two days later**: I also added a Java implementation to the mix.

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

Note that this is the exact same algorithm in all cases - a plain recursion
visiting the *word space* of HexSpeak, in exactly the same order.

These results more or less match my expectations when I started this 
Clojure experiment... Clojure is much faster than Python, but it's also
slower than plain Java. PyPy's performance surprised me, to be honest.

## Test me, Luke

All 3 report the same number of 14-length HexSpeak phrases (3020796).
I added an expect script to avoid regressions while I was testing changes
in the code:

    $ make test

    Verifying Clojure result...
    Clojure tested successfully!
    
    Verifying Java result...
    Java tested successfully!
    
    Verifying CPython result...
    CPython tested successfully!
    
    Verifying PyPy result...
    All tests successful!

## Concluding thoughts

I liked playing with Clojure. I have [a soft spot for Lisps](https://www.thanassis.space/score4.html#lisp)
so it was interesting to play with one again. And even though this benchmark
reminded me that *there's no such thing as a free lunch* (i.e. Clojure is slower than Java),
Clojure's immutable way of working shields your code from tons of bugs (e.g. contrast
[this mutation in Java](https://github.com/ttsiodras/HexSpeak/blob/master/contrib/hexspeak.java#L59)
with [this immutable addition in Clojure](https://github.com/ttsiodras/HexSpeak/blob/master/src/thanassis/hexspeak.clj#L50).

All in all, this was fun - and quite educational. Thanks go to all the people that chimed in
the discussion at [Reddit/Clojure](https://www.reddit.com/r/Clojure/comments/4l28go/pitting_clojure_against_python_in_hexspeak/).
