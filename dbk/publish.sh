#!/bin/bash
# publish.sh

echo "Starting to publish Dissertation."
#. ./bash_bits/diss_prep.sh
echo "Finished with diss prep."
#. ./bash_bits/publish_epub.sh
. ./bash_bits/publish_xhtml_txt.sh
#. ./bash_bits/publish_pdf.sh
#. ./bash_bits/titlepage.sh
#. ./bash_bits/cleanup.sh
