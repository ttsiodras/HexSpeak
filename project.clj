(defproject thanassis "0.1.0-SNAPSHOT"
  :description "HexSpeak - playing with Clojure and Python"
  :url "https://github.com/ttsiodras/HexSpeak"
  :license {:name "GNU Public License"
            :url "http://www.gnu.org/licenses/gpl-3.0.en.html"}
  :dependencies [[org.clojure/clojure "1.7.0"]]
  :aot [thanassis.hexspeak]
  ; :main ^:skip-aot thanassis.hexspeak
  :main thanassis.hexspeak
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
