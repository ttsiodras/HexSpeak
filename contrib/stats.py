#!/usr/bin/env python2
import math

from sys import stdout

# Colored message ANSI constants
g_green = chr(27) + "[32m" if stdout.isatty() else ""
g_yellow = chr(27) + "[33m" if stdout.isatty() else ""
g_normal = chr(27) + "[0m" if stdout.isatty() else ""


def printStatsOfList(results, label='Statistics', summaryOnly=False):
    total = totalSq = n = 0
    allOfThem = []
    for a in results:
        total += a
        totalSq += a*a
        n += 1
        allOfThem.append(a)
    if n == 0:
        return
    varianceFull = (totalSq - total*total/n)/n
    if varianceFull < 0.:
        varianceFull = 0.
    if n > 1:
        variance = (totalSq - total*total/n)/(n-1)
        if variance < 0.:
            variance = 0.
    else:
        variance = 0.
    srted = sorted(allOfThem)
    if summaryOnly:
        s = g_green + ("%6.2f" % (total/n)) + " +/- " + "%6.2f%%" + g_normal
        print s % ((100*math.sqrt(variance)*n/total) if total > 0 else 0.),
    else:
        print "\n", g_yellow+label+g_normal, ":"
        samplesNo = len(allOfThem)
        measurements = [
            ("Average value", total/n),
            ("Std deviation", math.sqrt(varianceFull)),
            ("Sample stddev", math.sqrt(variance)),
            ("Median",
                srted[samplesNo/2]
                if samplesNo % 2
                else 0.5*(srted[samplesNo/2 - 1] + srted[samplesNo/2])),
            ("Min", srted[0]),
            ("Max", srted[-1]),
            (g_green+"Overall", (str(total/n)+" +/- "+"%2.1f%%"+g_normal) %
                ((100*math.sqrt(variance)*n/total) if total > 0 else 0.))
        ]
        for label, value in measurements:
            print "%*s:" % (15, label),
            if isinstance(value, str):
                print value
            else:
                print "%.5f" % value


def readListOfIntegersOrFloatsFromStdin():
    while True:
        try:
            a = float(raw_input())
            yield a
        except:
            break

if __name__ == "__main__":
    printStatsOfList(readListOfIntegersOrFloatsFromStdin())
