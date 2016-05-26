(ns thanassis.hexspeak
  (:gen-class))

(set! *warn-on-reflection* true)

(defn good-words [rdr letters]
  (let [matcher (re-pattern (str "^[" letters "]*$"))
        forbidden #{"aaa" "aba" "abc"}]
    (doall (->> (line-seq rdr)
                (filter #(and (> (.length ^String %) 2)
                              (re-matches matcher %)
                              (not (contains? forbidden %))
                              ))))))

(defn get-words-per-length [dictionary-file letters]
  (let [candidates (with-open [rdr (clojure.java.io/reader dictionary-file)]
                     (good-words rdr letters))
        in-map-form (group-by #(.length ^String %)
                              (concat candidates ["a"]))
        max-length (inc (reduce max (keys in-map-form)))]
    (into [] (map #(get in-map-form % []) (range max-length)))))

(defn solve
  [words-per-length target-length phrase-len used-words counter]
  (dotimes [i (- target-length phrase-len)]
    (doseq [w (get words-per-length (inc i) [])]
      (if (not (contains? used-words w))
        (if (= target-length (+ i phrase-len 1))
          (vswap! counter inc)
          (solve words-per-length target-length (+ phrase-len (inc i)) (conj used-words w) counter))))))

(defn -main [& args]
  "Expects as cmd-line arguments:

      Desired length of phrases (e.g. 8)
      Letters to search for     (e.g. abcdef)
      Dictionary file to use    (e.g. /usr/share/dict/words)

  Prints the number of such HexSpeak phrases (e.g. 0xADEADBEE (a dead bee) is one"

  (let [phrase-length (Integer. ^String (re-find #"\d+" (nth args 0 4)))
        letters (nth args 1 "abcdef")
        dictionary-file (nth args 2 "/usr/share/dict/words")
        counter (volatile! 0)
        words-per-length (get-words-per-length dictionary-file letters)]
    (dotimes [n 10]
      (do
        (vreset! counter 0)
        (time (solve words-per-length phrase-length 0 #{} counter))
        (printf "Total: %d\n" @counter)))
        (flush)))
