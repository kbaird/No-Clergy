#!/usr/bin/env python
"""cleanup.py"""

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

import os, re, sys

inst = sys.argv[1]
argS = sys.argv[2]
listdirS = 'lilypond/xml/' + inst + '/'
bakdirS = 'lilypond/xml/bak/' + inst + '/'

if argS == 'ls':
  dir_listL = os.listdir(listdirS)
  dir_listL.sort()
  dir_listL.pop() # removes 'DTDs'
  for item in dir_listL:
  print 'list item =', listdirS, item
  last_itemS = dir_listL.pop()
  print 'last item =', listdirS, last_itemS
  print

elif argS == 'lsxml':
  dir_listL = os.listdir(listdirS)
  dir_listL.sort()
  dir_listL.pop() # don't consider 'DTDs'
  for item in dir_listL:
  if item[-3:] == 'xml':
  print 'list item =', listdirS, item
  last_itemS = dir_listL.pop()
  print 'last item =', listdirS, last_itemS
  print

elif argS == 'mv':
  dir_listL = os.listdir(listdirS)
  dir_listL.sort()
  dir_listL.pop() # don't consider 'DTDs'
  if len(dir_listL):
  last_itemS = dir_listL.pop()
  dir_listL.append(last_itemS)
  for item in dir_listL:
  if item[-3:] == 'xml':
  if not item == last_itemS:
    commandS = 'mv ' + listdirS + item
    commandS += ' ' + bakdirS
    os.popen2(commandS)

if os.listdir(bakdirS):
  dir_listL = os.listdir(bakdirS)
  any_XML_files = 0
  for item in dir_listL:
  if item[-3:] == 'xml':
  any_XML_files = 1

if any_XML_files:  
  os.popen2('bzip2 ' + bakdirS + '*.xml')
