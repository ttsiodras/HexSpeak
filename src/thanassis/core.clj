(ns thanassis.core
  (:gen-class))

(def targetLength 1)

(defn good-words [rdr]
  (let [letters "abcdef01"
        matcher (re-pattern (str "^[" letters "]*$"))]
    (doall (->> (line-seq rdr)
                ;(map #(.toLowerCase %))
                (filter #(and (> (.length %) 2)
                              (re-matches matcher %)
                              (not (contains? #{"aaa" "aba" "abc"}  %))))))))

(defn get-words-per-length []
  (let [input-file "/usr/share/dict/words"
        candidates (with-open [rdr (clojure.java.io/reader input-file)]
                     (good-words rdr))]
    (group-by #(.length %) (concat candidates ["a"]))))

(defn solve [words-per-length phrase phrase-len used-words]
  (if (= targetLength phrase-len)
    (printf "%s %s\n" used-words phrase)
    (for [i (range 1 (inc (- targetLength phrase-len)))
          w (get words-per-length i [])
          :when (not (contains? used-words w))]
      (solve words-per-length (str phrase w) (+ phrase-len i) (conj used-words w)))))

(defn -main [& args]
  (do
    (solve (get-words-per-length) "" 0 #{})
    (println)))
