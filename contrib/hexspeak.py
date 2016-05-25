#!/usr/bin/env python2

import re
import sys


def solve_recursive(words, currentPhrase, used, targetLength, results):
    currentLen = len(currentPhrase)
    for i in xrange(1, targetLength - currentLen + 1):
        for word in words.get(i, []):
            if word in used:
                continue
            newPhrase = currentPhrase + word
            if i != targetLength - currentLen:
                solve_recursive(words, newPhrase, used + [word], targetLength, results)
            else:
                # print used, '+', word, '=', newPhrase
                results.append(newPhrase)


def solve_nonrecursive(words, targetLength):
    from collections import deque
    candidates = deque([([], 0)])
    results = []
    while candidates:
        wordsSoFar, currentLen = candidates.popleft()
        if currentLen == targetLength:
            #print ' '.join(wordsSoFar)
            results.append(''.join(wordsSoFar))
        else:
            for i in xrange(1, targetLength - currentLen + 1):
                for word in words.get(i, []):
                    if word not in wordsSoFar:
                        candidates.append((wordsSoFar + [word], currentLen+i))
    return results


def solve_recursive_count(words, currentLen, used, targetLength, results):
    for i in xrange(1, targetLength - currentLen + 1):
        for word in words.get(i, []):
            if word in used:
                continue
            if i != targetLength - currentLen:
                solve_recursive_count(words, currentLen + i, used + [word], targetLength, results)
            else:
                results[0] += 1


def solve_nonrecursive_count(words, targetLength):
    from collections import deque
    candidates = deque([([], 0)])
    results = 0
    maxQ = 0
    while candidates:
        maxQ = max(maxQ, len(candidates))
        wordsSoFar, currentLen = candidates.popleft()
        if currentLen == targetLength:
            results += 1
        else:
            for i in xrange(1, targetLength - currentLen + 1):
                for word in words.get(i, []):
                    if word not in wordsSoFar:
                        candidates.append((wordsSoFar + [word], currentLen+i))
    print maxQ
    return results


def main():
    words = {}
    if len(sys.argv) == 1:
        letters = 'abcdef01'
        targetLength = 8
    else:
        letters = sys.argv[1].replace('0', 'o').replace('1', 'il')
        targetLength = int(sys.argv[2])
    m = re.compile(r'^[' + letters + ']*$')
    for word in open('/usr/share/dict/words'):
        word = word.strip()
        if len(word) > 2 and m.match(word):
            if word in ['aaa', 'aba', 'abc']:
                continue
            if word not in words.get(len(word), []):
                words.setdefault(len(word), []).append(word)
    words[1] = ['a']
    if False:
        results = solve_nonrecursive_count(words, targetLength)
        print "Total:", results
    else:
        results = [0]
        solve_recursive_count(words, 0, [], targetLength, results)
        print "Total:", results[0]
    import resource
    print resource.getrusage(resource.RUSAGE_SELF).ru_maxrss, "KB"

if __name__ == "__main__":
    main()
