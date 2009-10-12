def display_options(higher, lower, display_name, value_name, inst, selected=nil)
  output =<<END_OF_DISPLAY_OPTIONS
<td>
<table>
<tr>
<th colspan="3" class="bordered">#{display_name}:</th>
</tr>
<tr>
<td style="text-align: left;">#{higher}:</td>
<td>&nbsp;</td>
<td style="text-align: right;">#{lower}:</td>
</tr>
<tr>
#{show_cell(5, 1, inst, value_name, selected)}
#{show_cell(0, 0, inst, value_name, selected)}
#{show_cell(-1, -5, inst, value_name, selected)}
</tr>
</table>
</td>
END_OF_DISPLAY_OPTIONS
  return output
end # display_options

###

def show_cell(startpt, endpt, inst, value_name, selected)
  return '' if (endpt > startpt)
  output = "<td>\n"
  startpt.downto(endpt) do |val|
    output += show_val(val, inst, value_name, selected)
  end
  output += "</td>\n"
  return output
end # show_cell

###

def show_form(inst)
  shortH = {
    'Pitch'             => 'pitch',
    'Note Durations'    => 'dur',
    'Rests (silences)'  => 'rest',
    'Attacks'           => 'art', 
    'Volume'            => 'dyn'
  }
  highH = {
    'Pitch'             => 'higher',
    'Note Durations'    => 'longer',
    'Rests (silences)'  => 'more',
    'Attacks'           => 'sharper', 
    'Volume'            => 'louder'
  }
  lowH = {
    'Pitch'             => 'lower',
    'Note Durations'    => 'shorter',
    'Rests (silences)'  => 'fewer',
    'Attacks'           => 'smoother', 
    'Volume'            => 'softer'
  }
  
  output =<<END_OF_FORM_START
<form method="post" action="../cgi-bin/nc_feedback.cgi">
<h2 style="text-align: center; font-size: 4em;">inst = #{inst}</h2>
<table>
  <tr>
    <th class="category">Musical Characteristics</th>
    <th class="category">Range</th>
  </tr>
END_OF_FORM_START
  
  shortH.keys.each do |long|
    output += "  <tr>\n"
    output += display_options(highH[long], lowH[long], long, shortH[long], inst)
    output += display_options('wide', 'narrow', long, shortH[long] + 'var', inst, -5)
    output += "  </tr>\n"
  end # namesH
  
  output +=<<END_OF_FORM_END
</table>
<p><input type="submit" value="Change the music" /></p>
</form>
END_OF_FORM_END
  return output
end # show_form

###

def show_insts()
  require 'noclergy/instrument'
  insts = Dir.entries('/var/lib/noclergy/web/insts/')
  insts.delete('.')
  insts.delete('..')
  insts.delete('CVS')
  output = "<ul>\n" + insts.map do |inst|
    fname = Instrument.fullname(inst)
    notation_fragment = %Q[<a href="./insts/#{inst}/">player notation</a>]
    %Q(<li><a href="./?inst=#{inst}">#{fname}</a> (#{notation_fragment})</li>)
  end.join("\n") + "</ul>\n"
  return output
end # show_insts

###

def show_val(val, inst, value_name, selected)
  selected_rendered = (selected == val) ? %Q[ checked="checked"] : ''
  output =<<END_OF_SHOW_VAL
<input type="radio" name="#{inst + '_' + value_name}" value="#{val.to_s}"#{selected_rendered}>
END_OF_SHOW_VAL
  return output
end # show_val
