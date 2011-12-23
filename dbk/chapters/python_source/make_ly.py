#!/usr/bin/env python
"""make_ly.py"""

# Copyright (C) 2004 Kevin C. Baird
#
# This file is part of 'No Clergy'.
#
# No Clergy is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

import fileinput, os, random, re, sys, time
from noclergy_config import Config
from noclergy_header import Header
from noclergy_score import Score
from noclergy_measure import Measure
from noclergy_note import Note
from xml.dom.ext.reader import Sax2

########################################
## BEGIN GLOBAL VARIABLE DECLARATIONS ##
########################################

configDir = '/var/www/noclergy'

master_tupletL = []
# this is the tuplet list that gets used later in the program
temp_tupletL = [3, 3, 3, 5, 5]
# what types of non-power of 2 tuplets are allowed?
# repetitions give greater likelihood to repeated options, i.e.
# [3, 3, 3, 5, 5] means 60% of all tuplets will be triplets of
# some sort, and 40% of all tuplets will be fives of some sort
# (subject to other limitations specific to the placement of
# the tuplet set in the score)

ticks = 1
# how many timing ticks (a la MIDI) per 16th note?
while len(temp_tupletL):
  # tuplets start from a base 1/4 note value (ticks * 4),
  # and divide by their tuplet_type to get their ticks value
  tuplet_mod = temp_tupletL.pop()
  master_tupletL.append(tuplet_mod)   
  ticks *= tuplet_mod

# list of meter numerators
topL = [3, 4, 4, 5, 6, 6, 7, 8, 8, 9, 10, 10]
# x/4 meters are twice as likely, due to repetition above

try:
  inst = sys.argv[1]
except:
  inst = "you didn't specify an instrument with sys.argv[1]"

instD = {}
instsFile = open(configDir + '/insts.txt', 'r')
for line in instsFile.readlines():
  instS = line.split(' ')[1]
  transpositionS = line.split(' ')[3].strip()
  transpositionI = int(transpositionS)
  instD[instS] = transpositionI
instsFile.close()
scoreL = []

### END GLOBAL VARIABLE DECLARATIONS ###

#######################################
########### BEGIN MAIN BODY ###########
#######################################

# BEGIN instance declarations
config = Config()
config.readFile()
config.masterTupletL = master_tupletL
config.tempTupletL = temp_tupletL
config.ticksI = ticks
config.instS = inst
config.topL = topL
header = Header(config)
score = Score(instD[inst])
score.addVariables(config)
# END instance declarations

print header.ly_output(inst)
score.setTempo(180, 180) # min, max
score.construct(config)
score.filewrite(inst)
print score.printopen(inst)
#print score.debug_out()
print score.ly_output(config)
print score.printclose()

############ END MAIN BODY ############
