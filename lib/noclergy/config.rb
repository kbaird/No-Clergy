#!/usr/bin/env ruby
# config.rb
# $Id: config.rb,v 1.31 2006/07/15 22:03:45 kbaird Exp $

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

require 'noclergy/instrument'

=begin rdoc
"Wrapper" Object, similar to a <b>struct</b> in C, serving as a container for 
configuration variables.
=end
class Config < NoClergyObject

  CONFIG_BASENAME       = 'noclergy.conf'
  CONFIG_READ_ONLY_DIR  = '/etc/noclergy/'
  CONFIG_WRITE_DIR      = '/var/lib/noclergy/'
  BASE_WEB_DIR          = CONFIG_WRITE_DIR + 'web/'
  BASE_XML_DIR          = CONFIG_WRITE_DIR + 'xml/'

  CONFIG_FILE_HEADER = <<END_OF_HERE_DOC
# noclergy.conf, written by write_file method
# variable = [value]
# inst_variable = [value]
END_OF_HERE_DOC

  # Genuine web feedback first; otherwise initial feedback from installation
  FEEDBACK_BASENAME         = 'feedback.html'
  FEEDBACK_FILE_IN_PROCESS  = BASE_WEB_DIR + 'feedback/' + FEEDBACK_BASENAME
  FEEDBACK_FILE_READ_ONLY   = CONFIG_READ_ONLY_DIR + FEEDBACK_BASENAME

  FEEDBACK_FILE_INITIAL_CONTENTS = <<END_OF_HERE_DOC
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head><title>No Clergy Feedback Form</title></head>
<body>
<h1><cite>No Clergy</cite> Feedback Form</h1>
<!--begin-->
<pre>
</pre>

<hr />
<p>
Return to the <strong>No Clergy</strong>
<a href="../">Audience Feedback Form</a>.
</p>

</body>
</html>
END_OF_HERE_DOC

  # divisor explained in self.get_mod()
  DIVISOR_I = 3 

  # 8ths per minute
  MAX_TEMPO = 160 
  # 8ths per minute
  MIN_TEMPO = 160 

  # LAMBDAs
  WITH_PC_NAME_PROC      = lambda do |name| 
    name.include?('pc')
  end
  DUR_OR_PITCH_NAME_PROC = lambda do |name| 
    name.include?('dur') or name.include?('pitch')
  end

  attr_reader :instsA
  attr_reader :transpositionH
  attr_reader :varsH

  def initialize()
    super()

    setup_config_files()
    setup_feedback_file()

    @instsA = []
    @master_tupletA = []
        
    # from feedback.html: keys are 'art', 'dyn', 'rest', etc.
    # @modH values set within set_insts, as inst names are needed
    @modH = Hash.new(0) 
    
    # Will be multiplied, should start at 1
    @@ticks_per_I = 1 
    
    @topA = []
    
    read_insts()
    
    # from config file: keys are 'art', 'dyn', 'rest', etc.
    # Default value of 0 because of frequent use in addition
    @varsH = Hash.new(0) 
    @varsH['number_of_measures'] = 0
    CONFIG_VARS.each do |var| 
      @varsH[%Q(#{var}pc)] = 0
      @instsA.each do |inst|
        @varsH[%Q(#{inst}_#{var}pc)] = 0
      end # each inst
    end # each var
   
  end # initialize

  def add_inst_to_config_file(inst=@inst)
    File.open(@config_file['w'], 'a') do |configfile|
      fullname = Instrument.fullname(inst)
      trans = Instrument.transposition(inst)
      configfile.puts(%Q[inst #{inst} #{fullname} = #{trans}])
    end 
  end # add_inst_to_config_file

=begin rdoc
Alter the variables used by the random generation of the score, using the 
<tt>amplitude</tt> value (-5 to 5, excluding 0) to indicate the vector of the shift.
=end
  def alter(amplitude)
    @instsA.each do |inst| 
      set_pc(%Q[#{inst}_#{amplitude}])
    end
  end # alter

=begin rdoc
Use this to read user feedback used to alter pc variables. 
<b>Config#write_file</b> writes it out to the plain 
text file used by the <b>Score</b> Class.
=end
  def read_feedback()
    beginS = '<!--begin-->'
    endS = 'end 1 item'
    within_lines = false
    File.open(@feedback_file, 'r') do |feedback_file| 
      feedback_file.readlines.each do |line|
        within_lines = true if line.match(beginS)
        if (within_lines)
          read_vars(line, 'feedback')
          within_lines = false if line.match(endS)
        end # if within_lines
      end # readlines
    end # feedback_file
    generalize_vars()
  end # read_feedback

=begin rdoc 
Use this to read pc variables, both at start and after they 
have been altered by audience feedback. 
=end
  def read_file()
    File.open(@config_file['r'], 'r').readlines.each do |line| 
      read_vars(line, 'config')
    end # readlines
  end # read_file

=begin rdoc 
Get all instrument abbreviations and corresponding 
transposition levels (measured in semitones) from a file, defaulting to
the standard config read file.
=end
  def read_insts(inst_file_name=@config_file['r'])
    inst_namesH = read_inst_hash(inst_file_name)
    set_insts(inst_namesH)
  end # read_insts

=begin rdoc
Set some value of <tt>@varsH</tt> according to a given key.
=end
  def set_pc(inst_val)
    mod = get_mod(inst_val)
    new_val = @varsH[inst_val + 'pc'] + mod
    set_var(%Q(#{inst_val}pc), new_val)
  end # set_pc

=begin rdoc
Define variables used for meter and other timing.
=end
  def set_timing(ticks_per_I, master_tupletA, topA)
    @@ticks_per_I, @master_tupletA, @topA = ticks_per_I, master_tupletA, topA
  end # set_timing

=begin rdoc
Writes config variables into the working config file.
=end
  def write_file()
    insts_header = %Q(# inst name [fullname] = [transposition in semitones]\n)
    output = CONFIG_FILE_HEADER
    pc_vars = @varsH.keys.find_all(&WITH_PC_NAME_PROC)
    @instsA.each do |inst| 
      inst_vars = pc_vars.find_all { |key| key.include?(inst) }
      inst_vars.delete_if(&DUR_OR_PITCH_NAME_PROC)
      output += write_each_pc(inst_vars)
    end # @instsA.each
    output += %Q(number_of_measures = #{@varsH['number_of_measures'].to_s}\n)
    File.open(@config_file['w'], 'w') do |config_file| 
      config_file.puts(output + insts_header)
    end # config_file
    @instsA.each { |inst| add_inst_to_config_file(inst) }
  end # write_file

private

=begin rdoc
Cycle through each variable in <em>@varsH</em>, replacing values of zero 
(indicating that only <tt>base_</tt> prefix variables were present in the 
config file) with the value of the appropriate variable with no 
<tt>inst_</tt> prefix.
=end
  def generalize_vars()
    base_keys = ['artpc', 'dynpc', 'restpc']
    @varsH.each_key do |key|
      if (@varsH[key] == 0)
        base_key = key.split('_')[1]
        base_keys << base_key
        @varsH[key] = @varsH[base_key]
      end # if 0
    end # each_key
    base_keys.each { |bk| @varsH.delete(bk) }
  end # generalize_vars

=begin rdoc
Using audience feedback, determines the value (+ or -) 
added to a given pc variable.
=end
  def get_mod(valueS)
    non_inst_valueS = valueS.gsub(/.*_/, '')
    div_useI = DIVISOR_I * 5
    pcI = @varsH[%Q(#{valueS}pc)] || @varsH[%Q(#{non_inst_valueS}pc)]
    ampI = @modH[valueS]
    if ampI < 0: 
      modI = ((pcI * ampI) / div_useI)
    # reduce by as much as 1/divisor
    else 
      modI = ((100 - pcI) * ampI) / div_useI
    # increase by as much as 1/divisor * upper margin
    end # if
    return modI
  end # get_mod

  def get_var(line)
    line.split('=')[1].strip.to_i()
  end # get_var

=begin rdoc
Takes in each line from either the config file or the feedback file. 
String arg stageS='config' when reading from the config file; 
'feedback' when reading from the feedback file.
=end
  def read_vars(line, stageS)
    pattern_prefix = ''
    case stageS
      when 'config'
        var_hash = @varsH
      when 'feedback'
        var_hash = @modH
    end # case
    pattern_suffix = ' = .*'
    var_hash.each_key do |var|
      pattern = var + pattern_suffix
      if line.match(pattern):
        var_hash[var] = get_var(line)
      end # if match
    end # var_hash.each_key
  end # read_vars

=begin rdoc
Uses an instrument <b>Hash</b> of <tt>abbr</tt> => 
[<tt>fullname</tt>, <tt>transposition</tt>]. 
=end
  def set_insts(instsH)
    varsA = %w{ art dur dyn pitch rest }
    @instsA = instsH.keys.sort()
    @instsA.each do |inst|
      varsA.each do |var| 
        @modH[%Q(#{inst}_#{var})]    = 0
        @modH[%Q(#{inst}_#{var}var)] = 0
      end # varsA.each
    end # @instA.each
  end # set_insts

=begin rdoc
Either 'read' or 'write' for type, with appropriate dirs.
=end
  def setup_config_file(type, dirsA)
    if (type == 'w')
      @config_file['w'] = CONFIG_WRITE_DIR + CONFIG_BASENAME
      system("touch #{@config_file['w']}")
      read_file_contents = File.open(@config_file['r']).readlines.to_s()
      File.open(@config_file['w'], 'w') do |write_file| 
        write_file.puts(read_file_contents)
      end
      return
    else
      dirsA.each do |vardir|
        temp_filename = vardir + CONFIG_BASENAME
        if (File.exists?(temp_filename) && File.file?(temp_filename))
          @config_file[type] = temp_filename
          break
        end # if
      end # each vardir
    end # type
  end # setup_config_file

=begin rdoc
Both read and write, also called by CLI reset.
=end
  def setup_config_files()
    @config_file = Hash.new()
    setup_config_file('r', [CONFIG_WRITE_DIR, CONFIG_READ_ONLY_DIR])
    setup_config_file('w', [CONFIG_WRITE_DIR])
  end # setup_config_files

=begin rdoc
Either running web feedback or initial file from installation
=end
  def setup_feedback_file()
    @feedback_file = FEEDBACK_FILE_READ_ONLY
    if File.exists?(FEEDBACK_FILE_IN_PROCESS)
      if File.file?(FEEDBACK_FILE_IN_PROCESS)
        @feedback_file = FEEDBACK_FILE_IN_PROCESS
      end
    end
  end # setup_feedback_file

=begin rdoc
Writes pc variables into the working config file.
=end
  def write_each_pc(pc_vars, instS = '')
    pc_vars.sort.inject('') do |output,var| 
      output += instS + '_' if (instS.size > 0)
      output += %Q[var = #{bound(1, 99, @varsH[var]).to_s}\n]
    end # pc_vars.sort.inject
  end # write_each_pc

=begin rdoc
Writes each instrument's transposition level in semitones 
into the working config file.
=end
  def write_each_transposition(inst_abbr, fullname=nil, trans=nil)
    debug_no_inst_abbr(inst_abbr)
    fullname  ||= Instrument.fullname(inst_abbr)
    trans     ||= Instrument.transposition(inst_abbr).to_s()
    return %Q[inst #{inst_abbr} #{fullname} = #{trans}]
  end # write_each_transposition

end # class Config
