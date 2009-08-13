#!/usr/bin/env ruby
# note_list.rb
# $Id: note_list.rb,v 1.2 2006/02/04 15:21:33 kbaird Exp $

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

=begin rdoc
A specialized <b>Array</b> meant to hold <b>Note</b>s.
=end
class NoteList < Array

=begin rdoc
Duration filled so far, in 16ths.
=end
  def filled()
    inject(0) { |sum,note| sum += note.filled }
  end # filled

=begin rdoc
Used to know when done making tuplets, for example.
=end
  def some_non_rests?()
    any? { |n| !n.rest? }
  end # some_non_rests?

end # class NoteList
