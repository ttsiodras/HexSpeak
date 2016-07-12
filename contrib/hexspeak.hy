#!/usr/bin/env hy
"""
Yes, my madness is now officially beyond control...
This HexSpeak implementation is written using hylang - a Python based LISP :-)

Couldn't resist! Read about hylang here:

    http://docs.hylang.org/en/latest/

"""
(import re sys time)

(defn good-words [rdr letters]
  "Reads words from a with-open-ed stream and filters them
  to only include the ones that contain the letters passed.
  It also drops words of length 1 and 2, and drops
  3 'words' of length 3 that exist in /usr/share/dict/words"

  (let [matcher (.compile re (+ "^[" letters "]*$"))
        forbidden #{"aaa" "aba" "abc"}]
    (->> (.readlines (open rdr))
         (map (fn [x] (.strip x)))
         (filter (fn [x] (and (> (len x) 2)
                              (.match matcher x)
                              (not (in x forbidden))))))))

(defn get-words-per-length [dictionary-file letters]
  "The algorithm below (in solve) needs to access words of the same
  length, and a vector is much faster than a hashmap (which is what
  is returned by group-by below). This function uses good-words
  to generate the list of valid words, and then arranges them into
  a neat vector:

  [['a'] [] ['bee', 'fed', ...] ['dead', ...]]

  Valid words of length 1 are first, then valid words of length 2 (none),
  length 3, 4, etc..."

  (let [candidates (list (good-words dictionary-file letters))
        sorted-candidates (sorted candidates :key (fn [x] (len x)))
        grouped (group-by (cons "a" sorted-candidates) (fn [x] (len x)))
        in-map-form (dict
                      (list-comp
                        (, (get kv 0) (list (get kv 1)))
                        [kv grouped]))]
    (list (map (fn [i] (.get in-map-form (inc i) [])) (range (max in-map-form))))))

(setv counter 0)

(defn gget [l i default]
  "Returns l[i] if i fits - else default"
  (try
    (get l i)
    (except [IndexError] default)))

(defn solve
  [words-per-length target-length phrase-len used-words]
  "Using the list of valid options from our list of words,
  recurse to form complete phrases of the desired target-length,
  and count them all up to see how many there are."
  (for [i (range (- target-length phrase-len))]
    (for [w (gget words-per-length i [])]
      (if (not (in w used-words))
        (if (= target-length (+ i phrase-len 1))
          (do
            (global counter)
            (setv counter (inc counter)))
          (do
            (.add used-words w)
            (solve words-per-length target-length (+ phrase-len (inc i)) used-words)
            (.remove used-words w)))))))

(defmain [&rest args]
  "Expects as cmd-line arguments:

  - Desired length of phrases (e.g. 8)
  - Letters to search for     (e.g. abcdef)
  - Dictionary file to use    (e.g. /usr/share/dict/words)

  Prints the number of such HexSpeak phrases
  (e.g. 0xADEADBEE - a dead bee - is one of them)"
  (let [phrase-length (int (nth args 1 "8"))
        letters (nth args 2 "abcdef")
        dictionary-file (nth args 3 "/usr/share/dict/words")
        words-per-length (get-words-per-length dictionary-file letters)]
    (for [i (range 1)]
      (do
        (global counter)
        (setv counter 0)
        (setv before (.time time))
        (solve words-per-length phrase-length 0 #{})
        (setv after (.time time))
        (print (.format "Total: {} in {} ms." counter (* 1000 (- after before))))
        (. sys stdout flush)))))
