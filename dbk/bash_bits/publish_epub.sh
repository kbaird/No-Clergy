# Download DocBook-XSL 1.74.1 from
# https://sourceforge.net/project/showfiles.php?group_id=21935&package_id=16608&release_id=661947

cd out/epub
xsltproc /usr/share/sgml/docbook/stylesheet/xsl/docbook-xsl/epub/docbook.xsl ../../NoClergy.dbk
echo -n "application/epub+zip" > mimetype
zip -0Xq ../NoClergy.epub mimetype
zip -Xr9D ../NoClergy.epub META-INF/* OEBPS/*
cd ../
rm -rf epub/*
cd ../
