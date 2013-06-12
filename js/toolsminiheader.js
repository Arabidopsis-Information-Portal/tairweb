function toolsminiheader(active) {

  document.write("<span class=minilinks>")
		
  var separator=" | "

  if (active == "SeqViewer") { 
     document.write("SeqViewer")
  }		
  else {
    document.write("<a href=/servlets/sv>SeqViewer</a>");
  }

  document.write(separator)

  if (active == "MapViewer") {
    document.write("MapViewer")
  }
  else {
    document.write("<a href=/servlets/mapper>MapViewer</a>")
  }

  document.write(separator)

  if (active == "AraCyc") {
    document.write("AraCyc")
  }
  else {
    document.write("<a href=/tools/aracyc/>AraCyc</a>")
  }

  document.write(separator)

  if (active == "Blast") {
    document.write("Blast")
  }
  else {
    document.write("<a href=/Blast>BLAST</a>")
  }

  document.write(separator)

  if (active == "Wublast") {
    document.write("Wublast")
  }
  else {
    document.write("<a href=/wublast/index2.jsp>WU-BLAST2</a>")
  }

  document.write(separator)

  if (active == "FASTA") {
    document.write("FASTA")
  }
  else {
    document.write("<a href=/cgi-bin/fasta/nph-TAIRfasta.pl>FASTA</a>")
  }

  document.write(separator)

  if (active == "Patmatch") { 
    document.write("Pattern Matching")
  }
  else {
    document.write("<a href=/cgi-bin/patmatch/nph-patmatch.pl>Pattern Matching</a>")
  }

  document.write(separator)

  if (active == "Restriction") {
    document.write("Restriction Analysis")
  }
  else {
    document.write("<a href=/cgi-bin/patmatch/RestrictionMapper.pl>Restriction Analysis</a>")
  }

  document.write(separator)

  if (active == "Genehunter") {
    document.write("Gene Hunter")
  }
  else {
    document.write("<a href=/cgi-bin/geneform/geneform.pl>Gene Hunter</a>")
  }

  document.write(separator)

  if (active == "Motif") {
    document.write("Motif Analysis")
  }
  else {
    document.write("<a href=/tools/bulk/motiffinder/index.jsp>Motif Analysis</a>")
  }

  document.write(separator)

  if (active == "Bulk") {
    document.write("Bulk Download")
  }
  else {
    document.write("<a href=/tools/bulk>Bulk&nbsp;Downloads</a>")
  }

  document.write("</span>")
}


