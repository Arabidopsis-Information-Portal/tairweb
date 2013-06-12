function linksminiheader(active) {

  document.write("<span class=minilinks>")
		
  var separator=" | "

  if (active == "Stock") { 
     document.write("Arabidopsis Stock..")
  }		
  else {
    document.write("<a href=/links/atlinks.jsp>Arabidopsis Stock..</a>");
  }

  document.write(separator)

  if (active == "Insertion") {
    document.write("Insertion & Knockout..")
  }
  else {
    document.write("<a href=/links/insertion.jsp>Insertion & knockout..</a>")
  }

  document.write(separator)

  if (active == "Plant") {
    document.write("Plant Biology")
  }
  else {
    document.write("<a href=/links/plantresources.jsp>Plant Biology</a>")
  }

  document.write(separator)

  if (active == "Nomenclature") {
    document.write("Nomenclature..")
  }
  else {
    document.write("<a href=/links/nomenclature.jsp>Nomenclature..</a>")
  }

  document.write(separator)

  if (active == "Sequence") {
    document.write("Sequence Analysis..")
  }
  else {
    document.write("<a href=/links/webtools.jsp>Sequence Analysis..</a>")
  }

  document.write(separator)

  if (active == "Genome") { 
    document.write("Genome Databases")
  }
  else {
    document.write("<a href=/links/genomedbs.jsp>Genome Databases</a>")
  }

  document.write(separator)

  if (active == "Proteome") { 
    document.write("Proteome Resources")
  }
  else {
    document.write("<a href=/links/proteome.jsp>Proteome Resources</a>")
  }

  document.write(separator)

  if (active == "Cis") { 
    document.write("Cis-Element Resources")
  }
  else {
    document.write("<a href=/links/cis_element.jsp>Cis-Element Resources</a>")
  }

  document.write(separator)

  if (active == "Bioinformatics") {
    document.write("Bioinformatics Resources")
  }
  else {
    document.write("<a href=/links/bioinformatics.jsp>Bioinformatics Resources</a>")
  }

  document.write(separator)

  if (active == "Microarrays") {
    document.write("Microarrays")
  }
  else {
    document.write("<a href=/links/microarrays.jsp>Microarrays</a>")
  }
  document.write("</span>")
}


