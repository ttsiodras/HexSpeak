import sys
import re


def solve_recursive_count(words, currentLen, used, targetLength, cnt):
    for i in xrange(1, targetLength - currentLen + 1):
        for word in words[i]:
            if word in used:
                continue
            if i != targetLength - currentLen:
                solve_recursive_count(
                    words, currentLen + i, used + [word], targetLength, cnt)
            else:
                cnt[0] += 1


def solve_nonrecursive_count(words, targetLength):
    from collections import deque
    candidates = deque([([], 0)])
    cnt = 0
    while candidates:
        wordsSoFar, currentLen = candidates.popleft()
        if currentLen == targetLength:
            cnt += 1
        else:
            for i in xrange(1, targetLength - currentLen + 1):
                for word in words.get(i, []):
                    if word not in wordsSoFar:
                        candidates.append(
                            (wordsSoFar + [word], currentLen + i))
    return cnt


def main(argv):
    words = [[] for _ in xrange(128)]
    goodwords = [
        "abbe",
        "abed",
        "accede",
        "acceded",
        "ace",
        "aced",
        "add",
        "added",
        "baa",
        "baaed",
        "babe",
        "bad",
        "bade",
        "bead",
        "beaded",
        "bed",
        "bedded",
        "bee",
        "beef",
        "beefed",
        "cab",
        "cabbed",
        "cad",
        "cafe",
        "caff",
        "ceca",
        "cede",
        "ceded",
        "dab",
        "dabbed",
        "dace",
        "dad",
        "dded",
        "dead",
        "deaf",
        "deb",
        "decade",
        "decaf",
        "decaff",
        "deed",
        "deeded",
        "def",
        "deface",
        "defaced",
        "ebb",
        "ebbed",
        "eff",
        "efface",
        "effaced",
        "effed",
        "fab",
        "facade",
        "face",
        "faced",
        "fad",
        "fade",
        "faded",
        "faff",
        "faffed",
        "fed",
        "fee",
        "feed"
    ]
    targetLength = 14
    letters = 'abcdef'
    for word in goodwords:
        if word not in words[len(word)]:
            words[len(word)].append(word)
    words[1] = ['a']
    cnt = [0]
    import time
    start = time.time()
    solve_recursive_count(words, 0, [], targetLength, cnt)
    end = time.time()
    print cnt[0], "in", 1000*(end-start), "ms"
    return 0
    #
    # Not using recursion is much slower! Apparently cache is thrashed
    #
    # results = solve_nonrecursive_count(words, targetLength)
    # print "Total:", results
    # import resource # Proof this has much more memory impact...
    # print resource.getrusage(resource.RUSAGE_SELF).ru_maxrss, "KB"

def target(driver,args):
    return main,None

if __name__ == "__main__":
    main(sys.argv)
