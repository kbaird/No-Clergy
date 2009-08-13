#!/usr/bin/env ruby
# tupletable.rb
# $Id: tupletable.rb,v 1.14 2006/07/14 13:22:23 kbaird Exp $

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
Methods extracted from <b>Note</b> that deal specifically with tuplet rhythms.
=end
module Tupletable

  TUPLET_MARKER_THRESHOLD = 4

	attr_reader :tuplet_type

=begin rdoc
The purpose is to make sure the first note of
a <b>Score</b> always has an explicit dynamic mark.
=end
	def declare_first_sound_in_score(truth_value = true)
		@first_sound_in_scoreB = truth_value
	end # declare_first_sound_in_score

	def define_tuplet_vars()
    @first_non_rest_tupletB = false
    @ordinal_num_within_tuplet_set = nil
		
    # A tuplet puts @tuplet_type notes within the space of @tuplet_base normal notes
    @tuplet_type = 1
    @tuplet_base = nil
	end # define_tuplet_vars

=begin rdoc
Boolean predicate - returns true under two conditions:
- if the <b>Note</b> is not a tuplet at all
or
- if the <b>Note</b> is the last tuplet of its set
=end
  def done_with_tuplets?()
    return true unless tuplet?
    return true if last_tuplet_in_set?
    return false
  end # done_with_tuplets

=begin rdoc
Boolean predicate - first tuplet of a set?
=end
	def first_tuplet_in_set?()
		(@ordinal_num_within_tuplet_set == 1) && tuplet?
	end # first_tuplet_in_set?

=begin rdoc
A <b>Note</b> can't be both the first and last non-rest 
tuplet. This removes any such false positives.
=end
  def fix_false_double_non_rest_tuplet()
    if non_rest_tuplet?('first')
      if non_rest_tuplet?('last')
       @first_non_rest_tupletB = false 
        @last_non_rest_tupletB = false
      end # if last
    end # if first
  end # fix_false_double_non_rest_tuplet

	def last_tuplet_in_set?()
		(@ordinal_num_within_tuplet_set == @tuplet_type) && tuplet?
	end # last_tuplet_in_set?

=begin rdoc
Adds tuplet boundary markers as needed.
=end
	def ly_tuplet_markers()
		outputS = ''
		if @duration < TUPLET_MARKER_THRESHOLD:
			outputS += '[' if first_tuplet_in_set?
			outputS += ']' if last_tuplet_in_set?
		end # if shorter than than a quarter
		return outputS
	end # ly_tuplet_markers

# Sets the instance Boolean.
	def make_first_non_rest_tuplet()
    @first_non_rest_tupletB = true
  end # make_first_non_rest_tuplet

=begin rdoc
Assigns <b>true</b> to appropriate instance Boolean.
=end
  def make_non_rest_tuplet(end_point)
    case end_point
      when 'first': @first_non_rest_tupletB = true
      when 'last': @last_non_rest_tupletB = true
    end # case
    end # make_non_rest_tuplet

# Sets @ordinal_num_within_tuplet_set and @tuplet_type
  def make_non_tuplet()
		@ordinal_num_within_tuplet_set = 0
		@tuplet_type = 1
	end # make_non_tuplet

=begin rdoc
Makes the <b>Note</b> a tuplet of type and num args.
=end
	def make_tuplet(tuplet_type, ordinal_num_within_tuplet_set)
		@tuplet_type = tuplet_type
		@tuplet_base = tuplet_type-1 ### FIXME: have more flexibles types (7:4, etc.)
    @ordinal_num_within_tuplet_set = ordinal_num_within_tuplet_set
	end # make_tuplet

# Boolean predicate, if of specified end point type
	def non_rest_tuplet?(end_point)
		case end_point
			when 'first': @first_non_rest_tupletB 
			when 'last': @last_non_rest_tupletB
		end # case
	end # non_rest_tuplet?

	def tuplet?()
		@tuplet_type > 1
	end # tuplet?

private

=begin rdoc
Outputs MusicXML[http://www.recordare.com/xml.html] for the 
<em>time-modification</em> tag of a <b>Note</b>.
=end
	def file_write_tuplet_time()
		return '' unless tuplet?
    return <<END_OF_FILE_WRITE_TUPLET_TIME
  <time-modification>
    <actual-notes>#{@tuplet_type.inspect}</actual-notes>
    <normal-notes>#{get_nearest_2_power(@tuplet_type).inspect}</normal-notes>
  </time-modification>
END_OF_FILE_WRITE_TUPLET_TIME
	end # file_write_tuplet_time

=begin rdoc
Outputs MusicXML[http://www.recordare.com/xml.html] for the 
<em>tuplet</em> tag of a <b>Note</b>.
=end
	def file_write_tuplet_type()
		output = ''
		output += '    <tuplet type="start"/>' if first_tuplet_in_set?
		output += '    <tuplet type="stop"/>' if last_tuplet_in_set?
		return output + "\n"
	end # file_write_tuplet_type

  def first_of_stretched_tuplet_set?()
    first_tuplet_in_set? && (tuplets_stretch?)
  end

  def first_stretched_duration()
    @duration * (ordinals_to_ignore.abs+1)
  end

=begin rdoc
Outputs tuplet declarations for a <b>Note</b> in 
Lilypond[http://lilypond.org/] format.
=end
	def ly_output_tuplet_open()
		output =<<END_OF_TUPLET_OPEN

\\times #{(@tuplet_type-1).inspect}/#{@tuplet_type.inspect} { 
END_OF_TUPLET_OPEN
		return output
	end # ly_output_tuplet_open

=begin rdoc
Reads the <time-modification> tags from XML, makes tuplets accordingly.
=end
  def make_tuplets_from_XML(noteTag)
		noteTag.getElementsByTagName('time-modification').each do |timeModTag|
      tuplet_type = 0
      ordinal_num_within_tuplet_set = -1 # overwritten by assign_XML_tuplet_nums
      actualNotesNode = timeModTag.getElementsByTagName('actual-notes')
      tuplet_type = actualNotesNode[0].firstChild.data.to_i()
			make_tuplet(tuplet_type, ordinal_num_within_tuplet_set) if tuplet_type > 0
		end # timeModTag
	end # make_tuplets_from_XML_DOM

  def ordinals_to_ignore()
    return 0 unless tuplet?
    (@tuplet_type - @tuplet_base)
  end

  def tuplets_stretch?()
    tuplet? && (ordinals_to_ignore < 0)
  end
  
  def within_tuplet_nums_to_ignore?()
    tuplet? && (@ordinal_num_within_tuplet_set <= ordinals_to_ignore)
  end

end # module Tupletable
