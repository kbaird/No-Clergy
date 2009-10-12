#!/usr/bin/env ruby
# no_clergy_object.rb
# $Id: no_clergy_object.rb,v 1.14 2006/07/14 13:22:02 kbaird Exp $

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

['debugable', 'object', 'symbol'].each do |filename|
    require 'noclergy/' + filename
end

=begin rdoc
Superclass, contains Methods used by multiple objects.
=end
class NoClergyObject

  include Debugable

  CONFIG_VARS = %w{ art dyn rest tuplet }

	attr_reader :master_tupletA
	attr_reader :ticks_perI
	attr_reader :topA

	def initialize()
    @mutating = false
    @within_lines = false
	end # initialize

=begin rdoc
Reads 'global' configuration variables from the 
<b>Config</b> 'wrapper' Object.
=end
	def add_variables(config)
    @config = config
		@varsH = config.varsH
		@ticks_perI = config.ticks_perI
		@master_tupletA = config.master_tupletA
		@topA = config.topA
	end # add_variables

=begin rdoc
Returns <tt>value</tt> such that 
<tt>minval</tt> <= <tt>value</tt> 
<= <tt>maxval</tt>
=end
	def bound(minval, maxval, value)
    bounded = [minval, value].max
    bounded = [maxval, bounded].min
		return bounded
	end # bound

=begin rdoc
Reads the instrument abbreviation or transposition from noclergy.conf.
FIXME: Inst characteristic reading not very robust yet.
=end
  def get_inst_data_from_line(line, what_to_get)
    if line.lstrip[0, 4] == 'inst':
      lineA = line.split('=')
      case what_to_get
        when 'abbr': 
          return lineA[0].split(' ')[1]
        when 'transposition': 
          trans = lineA[1].split(' ')[0].to_i
          return trans
        when 'fullname': 
          if lineA[0].split(' ').size > 1:
            nameA = lineA[0].split(' ')
            nameA.delete('inst')
            nameA.shift
            return nameA.join(' ')
          end
        when 'clef':
          clef = lineA[1].split(' ')[2]
          return clef
        when 'range':
          range = Array.new()
          range.push(lineA[1].split(' ')[4].to_i)
          range.push(lineA[1].split(' ')[5].to_i)
          return range
      end # case what_to_get
    end # if starts with 'inst'
    return '' # failsafe
  end # get_inst_data_from_line

=begin rdoc
Return a <b>Hash</b> with keys of inst abbreviation and a value of an
<b>Array</b> of fullname and transposition.
=end
  def read_inst_hash(inst_file_name)
    instsH = Hash.new()
    File.open(inst_file_name, 'r').readlines.each do |line| 
      abbr = get_inst_data_from_line(line, 'abbr')
      clef = get_inst_data_from_line(line, 'clef')
      fullname = get_inst_data_from_line(line, 'fullname')
      range = get_inst_data_from_line(line, 'range')
      transposition = get_inst_data_from_line(line, 'transposition')
      if (abbr.size > 0)
        instsH[abbr] = [fullname, transposition]
        instsH[abbr].push(clef) if clef
        instsH[abbr].push(range) if range
      end # abbr.size > 0
    end # readlines
    return instsH
  end # read_inst_hash

	def set_mutating_status(status)
		@mutating = status
	end # set_mutating_status

=begin rdoc
Writes value into <tt>NoClergyObject.varsH</tt> hash
=end
	def set_var(key, value)
		if @varsH.has_key?(key): 
			@varsH[key] = value 
		else 
			fail "Trying to write to a nil key of @varsH"
		end
	end # set_var

private

=begin rdoc
Returns <b>true</b> if <tt>beginS</tt> has been found until <tt>endS</tt> 
has been found. Used for getting data from XML and config files.
=end
	def within_lines?(beginS, endS, line)
		@within_lines = true if line.include?(beginS)
		if @within_linesB
			@within_linesB = false if line.include?(endS)
		end # if within_linesB
		return @within_linesB
	end # within_lines

end # class NoClergyObject
