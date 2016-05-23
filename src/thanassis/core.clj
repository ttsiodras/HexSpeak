(ns thanassis.core
  (:gen-class))

(defn good-words [rdr letters]
  (let [matcher (re-pattern (str "^[" letters "]*$"))]
    (doall (->> (line-seq rdr)
                (filter #(and (> (.length %) 2)
                              (re-matches matcher %)
                              (not (contains? #{"aaa" "aba" "abc"}  %))))))))

(defn get-words-per-length [letters]
  (let [input-file "/usr/share/dict/words"
        candidates (with-open [rdr (clojure.java.io/reader input-file)]
                     (good-words rdr letters))]
    (group-by #(.length %) (concat candidates ["a"]))))


(defn lazy-cat' [colls]
  (lazy-seq
    (if (seq colls)
      (concat (first colls) (lazy-cat' (next colls))))))


(defn solve [words-per-length target-length phrase phrase-len used-words results]
  (if (= target-length phrase-len)
    (cons phrase results)
    (lazy-cat' (for [i (range 1 (inc (- target-length phrase-len)))
                        w (get words-per-length i [])
                        :when (not (contains? used-words w))]
                    (solve words-per-length target-length (str phrase w) (+ phrase-len i) (conj used-words w) results)))))

(defn -main [& args]
  (let [f1 (first args)
        f2 (second args)
        phrase-length (if (nil? f1) 4 (Integer. (re-find #"\d+" f1)))
        letters (if (nil? f2) "abcdef" f2)
        res (solve (get-words-per-length letters) phrase-length "" 0 #{} [])]
    (do
      (if (= (System/getenv "SHOWALL") "1")
        (doall (map #(printf "%s\n" %) res))
        (printf "Total: %d\n" (count res)))
      (flush))))
