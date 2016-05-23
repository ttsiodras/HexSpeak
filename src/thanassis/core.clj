(ns thanassis.core
  (:gen-class))

(def targetLength 1)

(defn good-words [rdr]
  (let [letters "abcdef01"
        matcher (re-pattern (str "^[" letters "]*$"))]
    (doall (->> (line-seq rdr)
                (map #(.toLowerCase %))
                (filter #(and (> (.length %) 2)
                              (re-matches matcher %)
                              (not (contains? #{"aaa" "aba" "abc"}  %))))))))

(defn get-words-per-length []
  (let [input-file "/usr/share/dict/words"
        candidates (with-open [rdr (clojure.java.io/reader input-file)]
                     (good-words rdr))]
    (group-by #(.length %) (concat candidates ["a"]))))

(defn solve [words-per-length phrase phrase-len used solutions]
  (if (= targetLength phrase-len)
    (cons phrase solutions)
    (let
      [res (for [i (range 1 (inc (- targetLength phrase-len)))
               words (get words-per-length i [])
               w words
               :when (not (contains? used w))]
           (solve words-per-length (str phrase w) (+ phrase-len i) (conj used w) solutions))]
      (do
        (printf "%s\n" (doall res))
        (apply concat res)))))

(defn -main [& args]
  (do
    (for [phrase (solve (get-words-per-length) "" 0 #{} [])]
      (printf "%s\n" phrase))
    (println)))
