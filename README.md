# Introduction - HexSpeak in Clojure and Python

(**Executive summary: Experiments in the land of Clojure**)

Results: compared to CPython, the same algorithm runs 2x faster
when written in Clojure and executed in a warmed-up JVM...

...but PyPy takes the gold medal: 3x faster than Clojure!

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

I added a `bench` rule in my Makefile, that measures 10 runs in CPython and Pypy
(via bash's `time`) and 10 executions in one run inside the JVM (via Clojure's
`time`, to avoid the JVM's startup cost and also warm-up the HotSpot technology).

Times in the JVM are in milliseconds - in the other two, it's just seconds.

*(Note: the benchmarking depends on my [stats.py](https://github.com/ttsiodras/utils/blob/master/stats.py)
being in the PATH)*.

So, Python first...

    $ make bench

    Benchmarking Python...
    2.575
    2.580
    ...
    2.559
    
    Statistics :
      Average value: 2.57430
      Std deviation: 0.01540
      Sample stddev: 0.01623
             Median: 2.57450
                Min: 2.55200
                Max: 2.60100
       Overall: 2.5743 +/- 0.6%

In my laptop, Python takes 2.5 seconds to find the number of 14-letter long
HexSpeak phrases.

What about Clojure's AOT-compiled code running in the JVM?

    Benchmarking JVM...
    1714.293231
    1213.169677
    ...
    1221.719871
    
    Statistics :
      Average value: 1325.81633
      Std deviation: 139.18757
      Sample stddev: 146.71658
             Median: 1302.97497
                Min: 1210.28791
                Max: 1714.29323
       Overall: 1325.8163335 +/- 11.1%

Twice as fast! Bravo, JVM!

What about PyPy?

    Benchmarking PyPy...
    0.456
    0.454
    ...
    0.454
    
    Statistics :
      Average value: 0.45170
      Std deviation: 0.00215
      Sample stddev: 0.00226
             Median: 0.45100
                Min: 0.44900
                Max: 0.45600
       Overall: 0.4517 +/- 0.5%

Yikes - 3x faster than the Clojure version.

Note that this is the exact same algorithm in all 3 cases - a plain recursion
visiting the *word space* of HexSpeak, in exactly the same order.
I suspect that PyPy somehow makes better use of my CPU's cache.

## Test me, Luke

All 3 report the same number of 14-length HexSpeak phrases:

    $ make test
    Testing...
    
    Verifying Java result...
    spawn java -jar target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar 14 abcdef
    "Elapsed time: 1622.970973 msecs"
    Total: 3020796
    
    Java tested successfully!
    
    Verifying CPython result...
    spawn python2 ./contrib/hexspeak.py abcdef 14
    Total: 3020796
    
    CPython tested successfully!
    
    Verifying PyPy result...
    spawn python2 ./contrib/hexspeak.py abcdef 14
    Total: 3020796
    
    All tests successful!

## Thoughts

Liked playing with Clojure. Ah, the LISPs... once you meet them, you can never forget them.

They keep calling you back... :-)

## License

Surely you're joking, Mr Feynmann.

Fine, have a GNU one (see file COPYING).
