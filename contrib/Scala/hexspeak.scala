import scala.collection.mutable.HashMap
import scala.util.matching.Regex
import scala.io.Source

object HexSpeak {

  def get_words_per_length(dictionaryFile: String, letters: String) = {
    val p = new Regex("^[" ++ letters ++ "]*$")
    val forbidden = List("aaa", "aba", "abc")
    ("a" :: Source.fromFile(dictionaryFile).getLines().filter(
      l =>
        l.length > 2 &&
        p.findFirstIn(l).nonEmpty &&
        !forbidden.contains(l)).toList).
    groupBy(_.length)
  }

  var cnt = 0

  def solve_recursive_count(
    words:Map[Int, List[String]], currentLen:Int, used:List[String], targetLength:Int):Unit = 
    {
      for (i <- 1 to (targetLength - currentLen))
        for(word <- words.getOrElse(i, List()))
          if (!used.contains(word))
            if (i != targetLength - currentLen)
              solve_recursive_count(words, currentLen + i, word :: used, targetLength)
            else
              cnt += 1
    }

  def main(args: Array[String]) {
    val words = get_words_per_length("../words", "abcdef")
    for(i <- 1 to 10) {
      cnt = 0
      val s = System.currentTimeMillis
      solve_recursive_count(words, 0, List(), 14)
      println(cnt + " in " + (System.currentTimeMillis - s) + " ms")
    }
  }
}
