#!/usr/bin/env python
"""mutate_config.py"""

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

#######################################
########### BEGIN VARIABLES ###########
#######################################

instsL = sys.argv[1:] # all but mutate_config.py itself

#######################################
########### BEGIN MAIN BODY ###########
#######################################

# BEGIN instance declarations
configSet = ConfigSet()
configSet.setInsts(instsL)
configSet.readFile()
configSet.readFeedback()
configSet.alter('art')
configSet.alter('dyn')
configSet.alter('rest')
#config.alter('tuplet', config.modTupletI)
print configSet.writeFile()

############ END MAIN BODY ############
