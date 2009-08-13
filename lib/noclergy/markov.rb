#!/usr/bin/env ruby
# markov.rb
# $Id: markov.rb,v 1.3 2006/01/27 18:42:19 kbaird Exp $

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

['note', 'note_holder'].each do |filename|
    require 'noclergy/' + filename
end

=begin rdoc
A set of operations dealing with <b>Markov chains</b>, organized into a single Object.
=end
class Markov

  include Debugable

	MARKOV_KEYS_A = %w{ art dur dyn midi_pitch }

	attr_reader :markovH
	attr_reader :orderI

=begin rdoc
Create empty <b>Hash</b>es for each <b>Note</b> attribute.
=end
  def initialize(orderI=2)
    @markovH = {}
		MARKOV_KEYS_A.each { |att| @markovH[att] = Hash.new() }
	  @notesA = NoteList.new()
    @orderI = orderI
	end # initialize

=begin rdoc
Wrapper method, eventually replace fixed 2nd order with variable order.
=end
	def construct(att, notesA)
		construct_f2(att, notesA)
	end # construct

=begin rdoc
Constructs a fixed 2nd order <b>Markov Chain</b> for a given attribute from an <b>Array</b> of <b>Note</b>s.
=end
	def construct_f2(att, notesA)
    @notesA = notesA
    orderI = 2
		fail 'no att: ' + att.class.to_s unless att
    @markovH[att] ||= {}
		0.upto(notesA.size-(orderI)) do |i|
			fail notesA[i+1].class.to_s unless notesA[i+1]
      fail notesA[i+1].print_r() unless notesA[i+1].get_val(att)
      value = notesA[i+1].get_val(att)
			fail value.class.to_s unless proper_markov_member?(value)
			fail if (att == 'dyn' && value == ' ')
			prev_val = notesA[i].get_val(att)
			fail unless proper_markov_member?(prev_val)
			prev2_val = notesA[i-1].get_val(att)
			fail unless proper_markov_member?(prev2_val)
			fail unless (value && prev_val && prev2_val)
      debug_val([prev2_val, prev_val, value])
      @markovH[att][prev2_val] ||= {}
			@markovH[att][prev2_val][prev_val] ||= []
			@markovH[att][prev2_val][prev_val].push(value)
		end # 0.upto(notesA.size-1)
	end # construct

=begin rdoc
Constructs a variable order <b>Markov Chain</b> for a given attribute from an <b>Array</b> of <b>Note</b>s.
=end
	def constuct_variable_order(att, notesA)
		debugS = ''
		fail 'Zero Order Chain' unless @orderI > 0
		size = notesA.size()
		debugS += 'size = ' + size.inspect() + "\n"
		fail "Your Markov Chain Order is too big" unless @orderI < size
		previous_notesA = notesA.slice(@orderI.size).reverse()
		@markovH[att] = set_markov_vals(att, previous_notesA)
		fail @markovH.print_r()
	end # constuct_variable_order

=begin rdoc 
Outputs the next value in the Markov Chain based on the <b>Array</b> of previous values.
=end
	def extract(att, previousA)
		debug_markov_construction(previousA)
		extract_f2(att, previousA)
	end # extract

=begin rdoc
Output result of fixed 2nd order Markov Chain. When a value is unextractable, outputs 
get_att_array(att) from a random member of @notesA.
=end
	def extract_f2(att, previousA)
    prev1 = previousA[1]
		fail prev1.inspect() unless proper_markov_member?(prev1)
    prev2 = previousA[0]
    if @markovH[att][prev2]
      arr = @markovH[att][prev2][prev1] || Array.new(1, failsafe(att)) 
      extracted_value = arr[rand(arr.size)]
    else
      extracted_value = failsafe(att)
    end # if
    return extracted_value
	end # extract

# True if arg.class is in the list of acceptable member types.
	def proper_markov_member?(value)
		[String, Fixnum, Array, Hash].include?(value.class)
	end # proper_markov_member?

private

=begin rdoc
Returns get_val(att) for a random member of @notesA. 
Used when Markov Chain construction fails.
=end
  def failsafe(att)
    note = @notesA[rand(@notesA.size)]
    return note.get_val(att)
  end # failsafe

=begin rdoc
A recursive method, allowing for variable-order <b>Markov Chain</b>s. All keys are currently <b>Strings</b>. Changing keys to 
<b>Integers</b> where possible would probably result in a slight improvement to efficiency. However, since this code is not the 
speed bottleneck in my project, I've decided to keep the <b>Strings</b> for simplicity and robustness.

Note that <tt>previous_notesA[0]</tt> is the 'current' note, and <tt>att</tt> is some string representing a <b>Note</b>'s attributes, 
such as 'art', or 'midi_pitch'.
=end
	def set_markov_vals(att, previous_notesA, depthI=0)
		failS = 'depthI = ' + depthI.inspect()
		failS += ', notes = ' + previous_notesA.size.inspect()
		failS += ', note = ' + previous_notesA[depthI].inspect()
		fail failS unless previous_notesA[depthI]
		note = previous_notesA[depthI]
		fail 'note: ' + failS unless note
		value = note.get_val(att)
		return value if depthI == @orderI
		depthI += 1
		output = {}
		output[value] = set_markov_vals(att, previous_notesA, depthI)
		return output
	end # set_markov_vals

end # class Markov
