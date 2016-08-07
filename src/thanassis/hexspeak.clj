(ns thanassis.hexspeak
  (:gen-class))

(set! *warn-on-reflection* true)

(defn good-words [rdr letters]
  "Reads words from a with-open-ed stream and filters them
  to only include the ones that contain the letters passed.
  It also drops words of length 1 and 2, and drops
  3 'words' of length 3 that exist in /usr/share/dict/words"

  (let [matcher (re-pattern (str "^[" letters "]*$"))
        forbidden #{"aaa" "aba" "abc"}]
    (doall (->> (line-seq rdr)
                (filter #(and (> (.length ^String %) 2)
                              (re-matches matcher %)
                              (not (contains? forbidden %))))))))

(defn get-words-per-length [dictionary-file letters]
  "The algorithm below (in solve) needs to access words of the same
  length, and a vector is much faster than a hashmap (which is what
  is returned by group-by below). This function uses good-words
  to generate the list of valid words, and then arranges them into
  a neat vector:

  [['a'] [] ['bee', 'fed', ...] ['dead', ...]]

  Valid words of length 1 are first, then valid words of length 2 (none),
  length 3, 4, etc..."

  (let [candidates (with-open [rdr (clojure.java.io/reader dictionary-file)]
                     (good-words rdr letters))]
    (group-by #(.length ^String %) (concat candidates ["a"]))))

(defn solve
  "Using the list of valid options from our list of words,
  recurse to form complete phrases of the desired target-length,
  and count them all up to see how many there are."

  [words-per-length target-length phrase-len used-words counter]
  (dotimes [i (- target-length phrase-len)]
    (doseq [w (get words-per-length (inc i) [])]
      (if (not (contains? used-words w))
        (if (= target-length (+ i phrase-len 1))
          (vswap! counter inc) ;faster than swap! and atom
          (solve words-per-length target-length (+ phrase-len (inc i))
                 (conj used-words w) counter))))))

(defn -main [& args]
  "Expects as cmd-line arguments:

  - Desired length of phrases (e.g. 8)
  - Letters to search for     (e.g. abcdef)
  - Dictionary file to use    (e.g. /usr/share/dict/words)

  Prints the number of such HexSpeak phrases
  (e.g. 0xADEADBEE - a dead bee - is one of them)"

  (let [phrase-length (Integer. ^String (re-find #"\d+" (nth args 0 4)))
        letters (nth args 1 "abcdef")
        dictionary-file (nth args 2 "/usr/share/dict/words")
        counter (volatile! 0) ; faster than atom
        words-per-length (get-words-per-length dictionary-file letters)]
    (dotimes [n 10]
      (do
        (vreset! counter 0)
        (time (solve words-per-length phrase-length 0 #{} counter))
        (printf "Total: %d\n" @counter)))
        (flush)))
