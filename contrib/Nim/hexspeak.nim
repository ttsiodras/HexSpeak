#!/usr/bin/env python3

import os
import re
import times
import strutils
import sets

type WordCounts = array[128, seq[ptr string]]
type UsedWords = HashSet[ptr string]

# Probably violating Nim here: to optimize the speed of execution,
# like in C++, I "intern" the strings. Basically, when loading the
# words, I store them in this global container - and in the UsedWords
# container (mutated during the recursion below) I maintain the
# *pointers* to the words - instead of the words themselves. This
# means that when checking whether the container has seen a word before
# or not, the comparison compares pointers instead of strings.
#
# Much faster!
#
# But if a GC happens, we're hosed - ergo, why I believe I am violating
# all Nim's tenets by doing this :-) Am I? (see the uses of "addr"
# below to take the addresses of strings in this sequence.
var allWords : seq[string]

proc get_words_per_length(dictionaryFile:string, letters:string): WordCounts =
  var regexStr = r"^[" & letters & r"]*$"
  var m = re(regexStr)
  allwords.add("a")
  var p_a = addr allwords[0]
  for line in open(dictionaryFile).lines():
    var word = line.strip()
    if len(word) > 2 and match(word, m):
      if word in ["aaa", "aba", "abc"]:
        continue
      allWords.add(word)
      result[len(word)].add(addr allWords[^1])
  result[1].add(p_a)


proc solve_recursive_count(
    words: WordCounts, currentLen:int, used:ref UsedWords, targetLength:int, cnt:int):int =
  var cnt = cnt
  # echo "[-] currentLen:", currentLen, ", cnt:", cnt, ", used:", used.join(",")
  for i in countup(1, targetLength - currentLen):
    for word in words[i]:
      if word in used[]:
        continue
      if i != targetLength - currentLen:
        used[].incl(word)
        cnt = solve_recursive_count(
          words, currentLen + i, used, targetLength, cnt)
        used[].excl(word)
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
  var used = new UsedWords
  var start = now()
  var cnt = solve_recursive_count(words, 0, used, targetLength, 0)
  var stop = now()
  echo cnt, " in ", (stop-start).inMilliseconds, " ms."

main()
