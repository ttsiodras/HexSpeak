#!/usr/bin/env python2

import numpy as np
import matplotlib as mpl

## agg backend is used to create plot as a .png file
mpl.use('agg')

import matplotlib.pyplot as plt

## Read data from benchmarking session
#    "timings.python.txt",
#    "timings.clojure.txt",
languages = [
    "timings.cpython.txt",
    "timings.clojure.txt",
    "timings.shedskin.txt",
    "timings.hy_pypy.txt",
    "timings.pypy.txt",
    "timings.nim.txt",
    "timings.scala.txt",
    "timings.js.txt",
    "timings.java.txt",
    "timings.cpp.txt",
]

data_to_plot_and_filenames = [
    (
        lang.split('.')[1].capitalize(),
        np.asarray([float(x) for x in open("../results/" + lang) if x.strip()])
    )
    for lang in languages
]

# Create a figure instance
fig = plt.figure(1, figsize=(9, 6))

# Create an axes instance
ax = fig.add_subplot(111)

# Create the boxplot!
# Add patch_artist=True option to ax.boxplot() to get fill color
bp = ax.boxplot([x[1] for x in data_to_plot_and_filenames], patch_artist=True)

## Change outline color, fill color and linewidth of the boxes
for box in bp['boxes']:
    # change outline color
    box.set(color='#7570b3', linewidth=2)
    # change fill color
    box.set(facecolor='#1b9e77')

## Change color and linewidth of the whiskers
for whisker in bp['whiskers']:
    whisker.set(color='#7570b3', linewidth=2)

## Change color and linewidth of the caps
for cap in bp['caps']:
    cap.set(color='#7570b3', linewidth=2)

## Change color and linewidth of the medians
for median in bp['medians']:
    median.set(color='#b2df8a', linewidth=2)

## Change the style of fliers and their fill
for flier in bp['fliers']:
    flier.set(marker='o', color='#e7298a', alpha=0.5)

## Custom x-axis labels
ax.set_xticklabels([x[0] for x in data_to_plot_and_filenames],
                   fontdict={'fontsize': 9})
for tick in ax.yaxis.get_major_ticks():
    # tick.label.set_fontsize('x-small')
    tick.label.set_fontsize(9)
    # tick.label.set_rotation('vertical')

## Remove top axes and right axes ticks
ax.get_xaxis().tick_bottom()
ax.get_yaxis().tick_left()

# Set axis labels
latexify = lambda x: "$" + x.replace(' ', '\\ ') + "$"
ax.set_xlabel(
    latexify("Language used for implementation"),
    fontdict={'fontsize': 13})
ax.set_ylabel(
    latexify("Time (in ms) to count HexSpeak(14) phrases"),
    fontdict={'fontsize': 13})

# Save the figure
fig.savefig('boxplot.png', bbox_inches='tight')
