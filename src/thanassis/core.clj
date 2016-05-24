(ns thanassis.core
  (:require [clj-getrusage.core :refer (getrusage)])
  (:gen-class))

(set! *warn-on-reflection* true)

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
                     (good-words rdr letters))]
    (group-by #(.length ^String %) (concat candidates ["a"]))))

(def words-per-length (get-words-per-length "abcdef"))
(def target-length 15)

(defn solve
  ; [words-per-length target-length phrase phrase-len used-words results]
  [words-per-length target-length phrase-len used-words results]
  (if (= target-length phrase-len)
    (+ 1 results)
    (reduce + 0
            (for [i (range 1 (inc (- target-length phrase-len)))
                  w (get words-per-length i [])
                  :when (not (contains? used-words w))]
              (solve 
                words-per-length
                target-length
                ;(str phrase w)
                (+ phrase-len i)
                (conj used-words w)
                results)))))

(defn -main [& args]
  (let [f1 (first args)
        f2 (second args)
        phrase-length (if (nil? f1) 4 (Integer. ^String (re-find #"\d+" f1)))
        letters (if (nil? f2) "abcdef" f2)
        res (solve (get-words-per-length letters) phrase-length 0 #{} 0)]
    (do
      ;(if (= (System/getenv "SHOWALL") "1")
        ; (doall (map #(printf "%s\n" %) res))
        ;(printf "Total: %d, mem used: %s KB\n" (count res) (get (getrusage) :maxrss)))
        ;(printf "%d\n" res)
        (printf "Total: %d, mem used: %s KB\n" res (get (getrusage) :maxrss))
      (flush))))
