#!/usr/bin/env ruby
# score.rb
# $Id: score.rb,v 1.39 2007/07/30 12:42:20 kbaird Exp $

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

['measure', 'paper'].each do |filename|
  require 'noclergy/' + filename
end
#require 'yaml' ### FIXME Convert from XML to YAML

=begin rdoc
A <b>Score</b> is defined as a single page of notation for one 
instrument. This and its methods manage everything within
the '\score' brackets in a Lilypond[http://lilypond.org] file.
=end
class Score < NoteHolder

  # Change this as needed
  CREATOR = 'Kevin C. Baird'

  DEFAULT_PREVIOUS_DYNAMIC = 'mp'

  # And this
  LICENSE = 'the GNU GPL'

  # And this, of course
  LOCAL_DTD_PATH = '"file:///usr/local/share/sgml/MusicXML/DTDs/partwise.dtd"'

  WEB_TEMPLATE = Hash.new()
  WEB_TEMPLATE[:begin] = <<END_OF_HERE_DOC
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">

<head>
<meta http-equiv="refresh" content="10" />
<title>
END_OF_HERE_DOC

  WEB_TEMPLATE[:middle] = <<END_OF_HERE_DOC
for No Clergy</title>
<style>
@import url('../css/noclergy.php');
h1, h2 { display: none; }
</style>
</head>

<body>

<div id="notation">
<h1>No Clergy:</h1>
<p style="text-align:center;">
END_OF_HERE_DOC

  WEB_TEMPLATE[:end] = <<END_OF_HERE_DOC
</p>
</div>

</body>
</html>         
END_OF_HERE_DOC

  YEAR = Time.now.to_a[5]

	attr_reader :measuresA

=begin rdoc
Receives a transposition level in semitones.
=end
	def initialize(inst_abbr)
		super(inst_abbr)
		debug_inst()
		@measuresA = []
		@stepI = 0
		@alterI = 0
		@octaveI = 0
		@xml_dirname = ''
		set_XML_spool_dir()
	end # initialize

=begin rdoc
Collect all of each <b>Measure</b>'s <b>Note</b>s into <b>@notesA</b>.
=end
	def collect_notes()
		temp_notesA = NoteList.new()
    @measuresA.each { |mm| temp_notesA += mm.notesA }
		get_all_notes(temp_notesA)
	end # collect_notes

=begin rdoc
Creates this <b>Score</b>, including the entire list of <b>Measure</b>s.
=end
	def construct(config)
		debug_inst()
		add_variables(config)
    set_system_breaks()
    construct_measures(config)
  end # construct_measures

# As expected from name.
  def create_web_dir()
    web_dirname = BASE_WEB_DIR + 'insts/' + @inst.abbr() + '/'
    system("mkdir -p #{web_dirname}") unless File.directory?(web_dirname)
    File.open(web_dirname + 'index.html', 'w', 756) do |webfile|
      webfile.puts(WEB_TEMPLATE[:begin])
      webfile.puts(@inst.fullname)
      webfile.puts(WEB_TEMPLATE[:middle])
      webfile.puts('<img src="../../png/' + @inst.abbr + '-page1.png" />')
      webfile.puts(WEB_TEMPLATE[:end])
    end
  end # create_web_dir

=begin rdoc
Read most recent file "yyyy_ddd/hh_mm_ss_inst.xml", where inst == @inst.abbr
(written by <b>Score#file_write</b>), assign to XMLfile for processing.
=end
	def file_read(filename=nil)
		filename ||= get_filename_for_file_read()
    File.open(filename, 'r') do |xmlfile|
      from_XML_DOM(xmlfile)
    end # xmlfile
    die_unless_good_dyn()
	end # file_read

=begin rdoc
Write to file "yyyy_MM_dd-hh_mm_ss_inst.xml", where inst == @inst.abbr
within the directory <tt>@xml_dirname</tt>.
=end
	def file_write()
		filename = get_xml_write_file_name()
    output_of_all_measures = @measuresA.map(&:file_write).join('')
    output =<<END_OF_FILE_WRITE
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 1.0 Partwise//EN" #{LOCAL_DTD_PATH}>
  <score-partwise>
    <identification>
      <creator>#{CREATOR}</creator>
      <rights>Copyright (c) #{YEAR} #{CREATOR}, released under #{LICENSE}</rights>
    </identification>
    <part-list>
      <score-part id="P1"><part-name>#{@inst.abbr}</part-name></score-part>
    </part-list>
    <part id="P1">
#{output_of_all_measures}
    </part>
  </score-partwise>
END_OF_FILE_WRITE
    File.open(filename, 'w') { |xmlfile| xmlfile.puts(output) }
    #File.open(filename + '.yaml', 'w') { |yamlfile| YAML.dump(self, yamlfile) } ### FIXME Convert from XML to YAML
	end # file_write

  def get_inst()
    @inst
  end # get_inst

=begin rdoc
Determines the time-based filename, makes it writable
=end
  def get_xml_write_file_name()
	timeA = Time.new.localtime.to_a()
	filename = @xml_dirname
  filename += timeA[5].to_s + '_' # yyyy_
	4.downto(0) do |i|
		filename += digit_fix(timeA[i]) + '_'
	end # MM_dd_hh_mm_ss_
	filename += @inst.abbr + '.xml'
  system("touch #{filename}")
  return filename 
  end # get_xml_write_file_name

=begin rdoc
Fake variable method.
=end
  def instS()
    @inst.abbr()
  end # instS

=begin rdoc
Returns Lilypond[http://lilypond.org/] output for a <b>Score</b>.
=end
	def ly_output()
    return ly_output_mm() if @measuresA.size > 0
	end # ly_output

=begin rdoc
Makes the <b>Hash</b> used for mutation.
=end
	def make_feedbackH()
		feedbackH = {} # contains items like {'pitch': -2}, etc.
		feedbackFileS = ''
		File.new(@feedback_file, 'r').readlines do |line|
			
      begin # while within_lines?
				unless line.strip[0, 1] == '#'
					if line.include?(@inst.abbr):
						key = line.split('_')[1].split(' =')[0]
						val = line.split(' =')[1]
						feedbackH[key] = val if key && val
					end # if line.include?(@inst.abbr)
				end # unless #
			end while within_lines?('<!--begin-->', 'end 1 item', line)
		
    end # readlines
		return feedbackH
	end # make_feedbackH

=begin rdoc
Incorporates the newer variation-by-feedback setup whereby it occurs 
note-by-note within the piece, rather than the old method of simply 
changing config file variables before score generation.
=end
	def mutate_by_feedback(feedbackH)
		begin
			attsA = %w{ art dyn pitch }
			@measuresA.each do |mm| 
			  mm.set_previous_dyns(@previous_dyn_outputS)
				mm.notesA.each do |note| 
					attsA.each do |att|
						note.mutate_by_feedback(att, feedbackH)
					end # attsA.each
				end # mm.notesA.each
			end # @measuresA.each
		end if feedbackH
	end # mutate_by_feedback

=begin rdoc
FIXME: Make able to take Markov Chains of arbitrary order
Alter stored musical data in 'XMLfile' according to data
found in 'feedback', the file containing input taken from
the audience during the performance. The specific alterations
that they inspire may depend heavily on precedents such as
Iannis Xenakis' ideas in 'Formalized Music'.
=end
	def mutate_by_markov(feedbackH)
		die_unless_good_dyn()
		debug_notes_XML()
    require 'noclergy/markov'
		markov = Markov.new()
		attsA = %w{ art dur dyn midi_pitch }
		attsA.each { |att| markov.construct(att, @notesA) }
		markov.debug_markov_construction()
		prev_notesA = prev_notes_for_markov(markov)
    @measuresA.replace(@measuresA.map do |mm|
			begin # until new_mm.properly_filled?
				new_mm = Measure.new(mm.numI, @inst.abbr)
        new_mm.set_mutating_status(@mutatingB)
				new_mm.set_feedback(feedbackH)
				new_mm.add_variables(@config)
				new_mm.set_meter(mm.topI, mm.bottomI)
				new_mm.set_previous_dyns(@previous_dynS)
        new_mm.construct_by_markov(@tempoI, prev_notesA, markov)
				new_mm.construct(@tempoI, @previous_dynS, @has_declared_first_soundB)
			end until new_mm.properly_filled?
      new_mm
		end) # measuresA.map
	end # mutate_by_markov

=begin rdoc
Returns an <b>Array</b> of previous <b>Note</b>s equal in size 
to the order of the Markov Chain argument <tt>markov</tt>.
=end
  def prev_notes_for_markov(markov)
    prev_notesA = NoteList.new()
    temp_notesA = NoteList.new()
  	@notesA.each { |note| temp_notesA.push(note) }
	  temp_notesA.pop
	  1.upto(markov.orderI) do |i| 
      prev_notesA.push(temp_notesA.pop)
    end # 1.upto orderI
    return prev_notesA
  end # prev_notes_for_markov

=begin rdoc
Outputs Lilypond[http://lilypond.org/]-compliant ending boilerplate, 
including paper definitions and the MIDI block.
=end
	def print_close()
		return <<END_OF_PRINT_CLOSE
#{Paper.new(@tempoI).ly_output}
} % end new Voice
} % end new Staff
} % end score
} % end book
END_OF_PRINT_CLOSE
	end # print_close

=begin rdoc
Outputs Lilypond[http://lilypond.org/]-compliant starting boilerplate.
=end
	def print_open()
		### FIXME NOW: FInd a way to bring these back or remove them more cleanly
    return <<END_OF_PRINT_OPEN
\\book {
\\score {
  \\new Staff {
    \\new Voice {
    %\\stemNeutral
    %\\override Voice.DynamicText #'font-size = #-3
    %\\override Voice.SpacingSpanner #'shortest-duration-space = #50.0
    %\\tupletUp
    %\\set autoBeaming = ##t
    %\\override Staff.DynamicLineSpanner #'padding = #2.4
    %\\override Staff.TupletBracket #'padding = #1.8
    %\\set midiInstrument = "#{@inst.fullname}"

#{print_tempo_override if @tempoI > 0}
    \\clef #{@inst.clef}
END_OF_PRINT_OPEN
	end # print_open

=begin rdoc
Picks one value from a uniform distribution across the range. For a 
fixed value, suppley only one parameter. Values are eighth notes per 
minute.
=end
	def set_tempo(min_tempo, max_tempo=min_tempo)
		@tempoI = (min_tempo + rand(max_tempo - min_tempo)).floor
	end # set_tempo

private

=begin rdoc
Creates the list of <b>Measure</b>s for this <b>Score</b>.
=end
  def construct_measures(config)
    1.upto(@varsH['number_of_measures']) do |mm_num|
			mm = construct_one_measure(mm_num, config)
			fail unless mm.varsH['number_of_measures'] > 0
      @measuresA.push(mm)
			set_first_sound(mm)
			remember_dynamics(mm)
		end 
    die_unless_good_dyn()
	end # construct_measures

=begin rdoc
Creates one <b>Measure</b> in this <b>Score</b>.
=end
	def construct_one_measure(mm_num, config)
		begin
			debug_inst()
			mm = Measure.new(mm_num, @inst.abbr)
			mm.add_variables(config)
			mm.construct(@tempoI, @previous_dynS, @has_declared_first_soundB)
		end until mm.properly_filled?
		return mm
	end # construct_one_measure

=begin rdoc
Adds a '0' to single digit numbers within XML file names for consistent 
length.
=end
	def digit_fix(time)
		timeS = time.to_s
		timeS = '0' + timeS if timeS.size == 1
		return timeS
	end # digit_fix

=begin rdoc
Reads data from an XML file using the 
{Document Object Model}[http://www.w3.org/DOM/], using the required file 
"xml/dom/builder", currently provided on my Debian[http://debian.org/] system by 
the package <em>libxml-parser-ruby1.8</em>.
=end
	def from_XML_DOM(xmlfilename)
		require 'xml/dom/builder'
		builder = XML::DOM::Builder.new(0)
		builder.setBase("./")
		xmltree = builder.parse(xmlfilename, true)
		xmltree.documentElement.normalize()
		inst_abbr = get_tag_data(xmltree, 'part-name')
    set_inst(inst_abbr)
    note = Note.new(@inst.abbr) # keeps track of first sound status
		xmltree.getElementsByTagName('measure').each do |mmTag|
			# mmTag is a DOM Element
			mmTag.normalize()
			mmTag.getElementsByTagName('sound').each do |soundTag|
				@tempoI = soundTag.getAttribute('tempo').to_i
			end # soundTag
			mmTag.getElementsByTagName('time').each do |timeTag|
				@topI = get_tag_data(timeTag, 'beats').to_i
				@bottomI = get_tag_data(timeTag, 'beat-type').to_i
			end # timeTag
			mmNum = mmTag.getAttribute('number').to_i
			mm_from_XML = Measure.new(mmNum, @inst.abbr)
			mm_from_XML.set_previous_dyns(@previous_dynS)
      mm_from_XML.declare_first_sound_by_note(note)
      mm_from_XML.add_variables(@config)
			mm_from_XML.set_meter(@topI, @bottomI)
			mm_from_XML.set_tempo(@tempoI)
			note = mm_from_XML.from_XML_DOM(mmTag) # first sound status
			mm_from_XML.die_unless_good_dyn()
      mm_from_XML.debug_nil_durs()
      remember_dynamics(mm_from_XML)
      die_unless_good_dyn()
			set_first_sound(mm_from_XML)
      mm_from_XML.assign_XML_tuplet_nums()
      @measuresA.push(mm_from_XML)
		end # measure
	end # from_XML_DOM

=begin rdoc
Determines filename for the <b>file_read</b> method based on the 
contents of the XML directory.
=end
  def get_filename_for_file_read()
		good_filesA = []
		xmldir = Dir.new(@xml_dirname)
		filenamesA = xmldir.entries()
    ['.', '..', @inst.abbr()].each do |unused|
      filenamesA.delete(unused)
    end # remove unused listings
    filenamesA.each do |fileS| 
      fileS[-4, 4] = '.xml'
    end # entries to add
    filenamesA.sort()
    debug_no_xml_files(filenamesA)
    filename = filenamesA[0].to_s()
		filename = @xml_dirname + filename
    return filename
  end # get_filename_for_file_read

=begin rdoc
Output the contents of this <b>Score</b>'s <b>Measure</b>s in 
Lilypond[http://lilypond.org]-compliant format.
=end
	def ly_output_mm()
		outputS = ''
		previous_dynS = DEFAULT_PREVIOUS_DYNAMIC
		@measuresA.each do |mm|
      temp_mm = mm.dup
      output_mm = (temp_mm.properly_filled?) ? temp_mm : mm
			outputS += output_mm.ly_output(previous_dynS)
			previous_dynS = mm.previous_dyn_output
		end # @measuresA.each
		return outputS
	end # ly_output_mm

	def print_tempo_override()
		output =<<END_OF_TEMPO_OVERRIDE
  %\\override Score.MetronomeMark #'padding = #5
  %  \\tempo 8=#{@tempoI.to_s}
END_OF_TEMPO_OVERRIDE
		return output
	end # print_tempo_override

	def remember_dynamics(measure)
		@previous_dynS = measure.previous_dyn_outputS
	end # remember_dynamics

	def set_first_sound(measure)
		@has_declared_first_soundB = measure.has_declared_first_soundB
	end # set_first_sound

# Needed as separate method for XML reading.
  def set_inst(inst_abbr)
    @inst = Instrument.new(inst_abbr)
    set_XML_spool_dir()
  end # set_inst

=begin rdoc
Creates XML spool dir for <b>@inst</b>.
=end
  def set_XML_spool_dir()
    @xml_dirname = BASE_XML_DIR + @inst.abbr() + '/'
    system("mkdir -p #{@xml_dirname}") unless File.directory?(@xml_dirname)
	end # set_XML_spool_dir

end # class Score
