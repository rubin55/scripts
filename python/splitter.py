#!/usr/bin/env python

import io
import sys

file = io.open(sys.argv[1])
keep = io.open(sys.argv[1] + '_weghouden', 'w')
kill = io.open(sys.argv[1] + '_houden', 'w')

status = 'p'
counter = 0

for line in file:
    if line[0] == 'A':
        if line.find('Ag01') > 0:
            status = 'np'

    if status == 'np':
        if line[0] == 'A':
            if line.find('Ag01') <= 0:
                status = 'p'

    if status == 'p':
        keep.write(line)

    if status == 'np':
        kill.write(line)

    counter += 1
    if counter%1000 == 0:
        keep.flush()
        kill.flush()
        sys.stdout.write("\r%d" % counter)
        sys.stdout.flush()

sys.stdout.write("\r%d" % counter)
sys.stdout.write("\n")

keep.close()
kill.close()
