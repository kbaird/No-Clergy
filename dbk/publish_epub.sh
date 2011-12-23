# Download DocBook-XSL 1.74.1 from
# https://sourceforge.net/project/showfiles.php?group_id=21935&package_id=16608&release_id=661947

xsltproc -o ./out/epub /usr/local/src/docbook-xsl-1.74.1/epub/docbook.xsl NoClergy.dbk
cd out
mv META-INF epub/
mv OEBPS epub/
cd epub
zip ../NoClergy.epub META-INF/* OEBPS/*
cd ../
rm -rf epub
cd ../
