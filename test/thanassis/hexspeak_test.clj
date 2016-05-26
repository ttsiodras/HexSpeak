(ns thanassis.hexspeak-test
  (:require [clojure.test :refer :all]
            [thanassis.hexspeak :refer :all]))

(deftest a-test
  (testing "FIXME, I fail."
    (let [phrase-length 14
          letters "abcdef"
          dictionary-file "contrib/words"
          counter (volatile! 0)
          words-per-length (get-words-per-length dictionary-file letters)
          side-effect-me (solve words-per-length phrase-length 0 #{} counter)]
      (is (= @counter 3020796)))))
