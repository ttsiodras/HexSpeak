(ns thanassis.core
  (:gen-class))

(def targetLength 8)

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
                     (good-words rdr))
        words-per-length (group-by #(.length %) (concat candidates ["a"]))]
    words-per-length))

(defn solve [words-per-length current-phrase current-len used]
  (for [i (range 1 (inc (- targetLength current-len)))
        words (get words-per-length i [])]
    (loop [w words new-solutions []]
      (if-not (contains? used w)
        (let [new-phrase (str current-phrase w)
              new-used (conj used w)]
          (if (= i (- targetLength current-len))
            (printf "%s %s+%s = %s %d\n"
                    used
                    current-phrase
                    w
                    ; (clojure.string/replace new-phrase #"o|i|l" { "o" "0" "i" "1" "l" "7" })
                    new-phrase
                    i)
            (solve words-per-length new-phrase (+ current-len i) new-used)))))))

(defn -main [& args]
  (let [words-per-length (get-words-per-length)]
    (do
      (printf "Using %d categories...\n" (count words-per-length))
      (let [useless (doall (solve words-per-length "" 0 #{}))]
        (println useless)))))
