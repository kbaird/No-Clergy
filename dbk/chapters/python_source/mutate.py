#!/usr/bin/env python
"""mutate.py"""

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
from noclergy_configSet import ConfigSet
from noclergy_header import Header
from noclergy_score import Score
from noclergy_measure import Measure
from noclergy_note import Note
from noclergy_piece import Piece
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

# list of meter numerators
topL = [3, 4, 4, 5, 6, 6, 7, 8, 8, 9, 10, 10]
# x/4 meters are twice as likely, due to repetition above

ticks = 1
# how many timing ticks (a la MIDI) per 16th note?
while len(temp_tupletL):
  # tuplets start from a base 1/4 note value (ticks * 4),
  # and divide by their tuplet_type to get their ticks value
  tuplet_mod = temp_tupletL.pop()
  master_tupletL.append(tuplet_mod)
  ticks *= tuplet_mod

try:
  directory = sys.argv[1]
except:
  directory = 'lilypond/ly/'

# these lists are only used for sieve operations, not yet operational
c_dom_seventhL = [0, 4, 7, 10]
# the PCs in the C Dominant 7th Chord
c_major_scaleL = [0, 2, 4, 5, 7, 9, 11]
# the PCs in the C Major scale
c_major_triadL = [0, 4, 7]
# the PCs in the C Major scale

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
##### BEGIN FUNCTION DEFINITIONS ######
#######################################

def debugProperlyFilledScore(scoreL, instL):
  for i in range(len(scoreL)):
  score = scoreL[i]
  inst = instL[i]
  for measure in score.measures:
  if not measure.checkProperlyFilled():
  errorS = ': '
  for note in measure.notes:
    errorS += str(note.pitch) + str(note.dur) + ' '
  errorS += 'mm length = ' + str(measure.length) + ' '
  raise Exception, inst + ' ' + str(measure.num) + errorS

#####  END FUNCTION DEFINITIONS  ######

#######################################
########### BEGIN MAIN BODY ###########
#######################################

# BEGIN instance declarations
instL = []
for pair in instD.items():
  key = pair[0]
  instL.append(key)
configSet = ConfigSet()
configSet.setTiming(ticks, master_tupletL, temp_tupletL, topL)
configSet.setInsts(instL)
configSet.readFile()
for inst in instL:
  score = Score(instD[inst])
  for config in configSet.configsL:
  if config.instS == inst:
  score.addVariables(config)
  # inherited from Object.addVariables
  score.fileread(inst, config)
  scoreL.append(score)

for score in scoreL:
  for measure in score.measures:
  measure.addVariables(score.config)
  measure.removeDuplicateNotes()

piece = Piece(scoreL)
piece.get_all_notes()
#piece.sort_notes_in_mm(scoreL)
#piece.sieve_pitches(scoreL, c_dom_seventhL)
# optional 3rd arg of variance amp, default 3

for i in range(len(scoreL)):
  ly_file = open(directory + instL[i] + '.ly', 'w')
  current_score = scoreL[i]
  current_score.setMutatingStatus(1)
  feedbackD = current_score.makeFeedbackD()
  current_score.mutateByMarkov2(current_score.config, feedbackD)
  # some feedback must be incorporate at this point
  # for measure construction, even though most of 
  # the method is still Markovian
  current_score.mutateByFeedback(feedbackD)
  # do all other feedback-based mutations
  scoreL[i].filewrite(instL[i])
  header = Header(current_score.config)
  ly_file.write(header.ly_output(instL[i]))
  ly_file.write(current_score.printopen(instL[i]))
  ly_file.write(current_score.ly_output(config))
  ly_file.write(current_score.printclose())
  ly_file.close()

############ END MAIN BODY ############
