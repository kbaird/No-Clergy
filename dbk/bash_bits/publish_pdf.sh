#!/bin/bash
# publish_pdf.sh
# LDP stuff turned off until they actually have distinct sheets from 
# Norm Walsh's.

# with stock pagesetup.xsl
xmlto --skip-validation -o ./out fo ./NoClergy.dbk 

#xmlto --skip-validation -o ./out -x /usr/local/share/sgml/stylesheet/tldp/fo/tldp-print.xsl fo ./NoClergy.dbk 
#mv ./NoClergy.fo ./out/NoClergy-ldp.fo
echo "Finished creating FO files."
perl -pi -e 's/line-height="normal"/line-height="2em"/g' ./out/NoClergy*.fo
perl -pi -e 's/"1in - -4pc"/"1in"/g' ./out/NoClergy*.fo
echo "Finished fixing FO files."
echo "Starting FO -> PDF transformation."
xmlto --skip-validation -o ./out pdf ./out/NoClergy.fo 
echo "Finished with PDF with Norm Walsh's stylesheets."
#xmlto --skip-validation -o ./out pdf ./out/NoClergy-ldp.fo 
#echo "Finished with PDF with LDP stylesheets."

# with edited pagesetup.xsl
#xmlto pdf --skip-validation -o ./out/ -x ./stylesheets/titlepage.xsl ./NoClergy.dbk 

echo "Finished with pdf output."
