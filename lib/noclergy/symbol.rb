#!/usr/bin/env ruby
# symbol.rb
# $Id: symbol.rb,v 1.1 2006/07/11 22:03:59 kbaird Exp $

# Copyright (C) 2004-2009 Kevin C. Baird
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
Adding Symbol#to_proc as at 
http://blogs.pragprog.com/cgi-bin/pragdave.cgi/Tech/Ruby/ToProc.rdoc
=end
class Symbol

  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end

end # class Symbol
