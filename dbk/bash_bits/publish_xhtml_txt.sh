#!/bin/bash
# publish_xhtml_txt.sh

xmlto --skip-validation -o ./out/xhtml -m ./stylesheets/custom-html.xsl xhtml ./NoClergy.dbk 
perl -pi -e 's#<b>#<strong>#g' ./out/xhtml/*.html
perl -pi -e 's#</b>#</strong>#g' ./out/xhtml/*.html
perl -pi -e 's#\ xmlns=""##g' ./out/xhtml/*.html
perl -pi -e 's#\>\<title#\/\>\<title#g' ./out/xhtml/*.html
xmlto --skip-validation -o ./out -m ./stylesheets/custom-html.xsl xhtml-nochunks ./NoClergy.dbk 
perl -pi -e 's#<b>#<strong>#g' ./out/*.html
perl -pi -e 's#</b>#</strong>#g' ./out/*.html
perl -pi -e 's#\ xmlns=""##g' ./out/*.html
perl -pi -e 's#\>\<title#\/\>\<title#g' ./out/*.html
xmlto --skip-validation -o ./out txt ./NoClergy.dbk 
#cp ./out/xhtml/*.html /var/www/pub/NoClergy-html/
echo "Finished with xhtml and text output."
