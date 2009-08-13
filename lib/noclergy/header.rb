#!/usr/bin/env ruby
# header.rb
# $Id: header.rb,v 1.7 2006/05/05 18:26:48 kbaird Exp $

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

require 'noclergy/no_clergy_object'

=begin rdoc
Outputs a Lilypond[http://lilypond.org]-compliant header.
=end
class Header < NoClergyObject

  COMPOSER = 'Kevin C. Baird'
  COPYRIGHT_YEAR = 2005
  LILYPOND_VERSION = '2.2.6'
  LY_GLOBAL_STAFF_SIZE = 23
  RELEASE_TEXT = 'Released under the GNU General Public License (http://www.gnu.org)'
  SHOW_SUBTITLE = false

=begin rdoc
Calls NoClergyObject#add_variables
=end
	def initialize(config)
		add_variables(config) # inherited from NoClergyObject
	end # initialize

=begin rdoc
Prints Lilypond[http://lilypond.org] boilerplate (version, header, 
etc.) identifying me and this piece 
<b>{No Clergy}[http://noclergy.rubyforge.org/noclergy/]</b>.
=end
	def ly_output(inst)
		output =<<END_OF_LY_OUTPUT
\\version "#{LILYPOND_VERSION}"
\\include "english.ly"
\\header {
  title = "No Clergy" #{output_subtitle() if SHOW_SUBTITLE}
  instrument = "#{inst.fullname}"
  composer = "#{COMPOSER}"
  tagline = "Copyright (c) #{COPYRIGHT_YEAR.to_s}, #{COMPOSER}, #{RELEASE_TEXT}"
  }
  ##(set-global-staff-size #{LY_GLOBAL_STAFF_SIZE.to_s})
END_OF_LY_OUTPUT
		return output
	end # ly_output

private

=begin rdoc
Reads values from <tt>@varsH</tt>, converts to <b>String</b>.
=end
	def output_pc_var(key)
		@varsH[key].to_s
	end # output_pc_var

    def output_subtitle()
    subtitle_content = CONFIG_VARS.map do |var| 
      var + 'pc=' + output_pc_var(var + 'pc') + ', '
    end.join(', ')
		return %Q[\n  subtitle = "(#{subtitle_content})"\n]
    end # output_subtitle

end # class Header
