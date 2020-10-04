#!/usr/bin/env python3

import os
import re
import times
import strutils

type WordCounts = array[128, seq[string]]

proc get_words_per_length(dictionaryFile:string, letters:string): WordCounts =
  var regexStr = r"^[" & letters & r"]*$"
  var m = re(regexStr)
  for line in open(dictionaryFile).lines():
    var word = line.strip()
    if len(word) > 2 and match(word, m):
      if word in ["aaa", "aba", "abc"]:
        continue
      if not (word in result[len(word)]):
        result[len(word)].add(word)
  result[1].add("a")


proc solve_recursive_count(
    words: WordCounts, currentLen:int, used:seq[string], targetLength:int, cnt:int):int =
  var cnt = cnt
  # echo "[-] currentLen:", currentLen, ", cnt:", cnt, ", used:", used.join(",")
  for i in countup(1, targetLength - currentLen):
    for word in words[i]:
      if word in used:
        continue
      if i != targetLength - currentLen:
        cnt = solve_recursive_count(
          words, currentLen + i, used & @[word], targetLength, cnt)
      else:
        inc cnt
  cnt


proc main =
  var targetLength: int
  var letters: string
  var dictionaryFile: string
  if paramCount() != 3:
    targetLength = 8
    letters = "abcdef01"
    dictionaryFile = "/usr/share/dict/words"
  else:
    targetLength = paramStr(1).parseInt
    letters = paramStr(2).replace("0", "o").replace("1", "il")
    dictionaryFile = paramStr(3)
  var words = get_words_per_length(dictionaryFile, letters)
  # for i in countup(1, 127):
  #   if len(words[i]) != 0:
  #     echo "[-]", i, ":", join(words[i], ",")
  var start = now()
  var cnt = solve_recursive_count(words, 0, @[], targetLength, 0)
  var stop = now()
  echo cnt, " in ", (stop-start).inMilliseconds, " ms."

main()
