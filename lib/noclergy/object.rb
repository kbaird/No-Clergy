#!/usr/bin/env ruby
# object.rb
# $Id: object.rb,v 1.5 2006/07/15 22:04:23 kbaird Exp $

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
Adds a method to the <b>Object</b> class based on the 
<b>print_r</b>[http://php.net/manual/en/function.print-r.php] 
function in <b>PHP</b>[http://php.net/]. Mainly useful for debugging.
=end

class Object

  COMPACT_PRINTR_OUTPUT_B = false
    
  # vary as desired.
	PRE_INDENT_I = 2
  PRE_INDENT_S = ' ' * PRE_INDENT_I

public

=begin rdoc
Prevents unusable values for fullname, transposition, etc.
=end
  def ensure_nil_if_unusable()
    return nil unless self
    return nil if (size < 1)
    return self
  end

=begin rdoc
Loosely duplicates the 
<b>print_r</b>[http://www.php.net/manual/en/function.print-r.php]
function in PHP[http://php.net].
=end
	def print_r(indentI=0)
		output = print_r_labelled_iv(indentI)
		if respond_to?('keys')
			output += print_r_items(keys.sort, self, indentI+PRE_INDENT_I)
		elsif respond_to?('each_index')
			tempH = Hash.new() # make a temporary Hash out of the Array (or similar)
			self.each_index { |i| tempH[i] = self[i] }
			output += print_r_items(tempH.keys.sort, tempH, indentI+PRE_INDENT_I)
		elsif can_do_18m?()
			output += to_s.chomp() unless more_iv_than?(0)
			# presumably, any object wth instance variables will 
			# already have been output if can_do_18m?() is true
		else
			output += inspect.chomp()
		end # if respond_to? keys/each_index
		return output
	end # print_r

private

=begin rdoc
Can this Object do instance variable methods new to Ruby 1.8 and unavailable earlier?
=end
	def can_do_18m?
		respond_to?('instance_variables') and respond_to?('instance_variable_get')
	end # can_do_18m?

=begin rdoc
Returns true if the Object has more than <em>numI</em> number of instance variables.
=end
	def more_iv_than?(numI)
		instance_variables.size > numI
	end # more_iv_than?

=begin rdoc
Returns an delimiter appropriate for the print_r method: the delimS argument 
for multi-item data structures, and a space for single-item data structures.
=end
	def print_r_delim(items, delimS, compactS=' ')
		return delimS unless COMPACT_PRINTR_OUTPUT_B
		return delimS if (items.size > 1)
		return compactS
	end # more_iv_than?

  def print_r_each_item(items, holder, indentI, indentS)
		items.inject('') do |out,item| 
			out += print_r_delim(items, indentS)
			out += "[#{item.to_s}] => "
			out += holder[item].print_r(indentI+(PRE_INDENT_I/2))
			out += print_r_delim(items, "\n")
		end # items.each
  end # print_r_each_item

  def print_r_labelled_iv(indentI)
		return '' unless more_iv_than?(0) 
		return <<END_OF_IV
#{self.class.to_s}
#{print_r_iv(indentI) if can_do_18m?}
END_OF_IV
 end # print_r_labelled_iv

=begin rdoc
Loops through items, matching PHP[http://php.net]'s output reasonably closely. It does, 
however, identify <b>Hash</b>es as such, rather than as <b>Array</b>s as in PHP[http://php.net].
=end
	def print_r_items(items, holder, indentI=0)
		indentS = PRE_INDENT_S*([indentI-(PRE_INDENT_I/2), 0].max)	# key/value indent amount
		parindS = PRE_INDENT_S*([indentI-PRE_INDENT_I, 0].max)	# parentheses indent, less at first
		return self.class.to_s +
		  print_r_delim(items, "\n") +
		  print_r_delim(items, parindS) + 
      '(' +
		  print_r_delim(items, "\n") +
      print_r_each_item(items, holder, indentI, indentS) +
		  print_r_delim(items, parindS) +
      ')'
	end # print_r_items

=begin rdoc
Outputs instance variables using methods new to Ruby 1.8 and unavailable earlier.
=end
	def print_r_iv(indentI)
		tempH = Hash.new()	# make a temporary Hash so instance var names are not lost
		instance_variables.each { |varname| tempH[varname] = instance_variable_get(varname) }
		inst_varA = tempH.print_r(indentI).split("\n")
		inst_varA.shift()	# remove 'Array' for instance_variables.each
		inst_varA.shift()	# remove 'Array' open parentheses
		inst_varA.pop()	# remove 'Array' close parentheses
		return inst_varA.join("\n")
	end # print_r_iv

end # class Object
