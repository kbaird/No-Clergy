#!/bin/bash
# noclergy.sh

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
#
# Kevin can be reached at 
# kcbaird@world.oberlin.edu or 
# http://kevinbaird.net

source ~/NoClergy/mv_oldfiles.sh
source ~/NoClergy/nc_functions.sh
# define functions and variables

instList=$(sed 's# =.*$##g' /var/www/noclergy/insts.txt | sed 's#inst ##g')

# -O flag to Python optimizes the module byte code files
python -O NoClergy/Python/mutate_config.py $instList > temp_config
mv temp_config $configFile
python -O NoClergy/Python/mutate.py 'lilypond/ly/'

for inst in $instList; do	# see note in setup.sh about the 3
  renderLy $inst		# different loops.
done

for inst in $instList; do
  cleanup $inst
done

source NoClergy/mv_output.sh
