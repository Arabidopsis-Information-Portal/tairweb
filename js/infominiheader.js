function infominiheader(active) {

  document.write("<span class=minilinks>")
		
  var separator=" | "

  if (active == "Aboutarabidopsis") { 
     document.write("About Arabidopsis")
  }		
  else {
    document.write("<a href=/info/aboutarabidopsis.jsp>About Arabidopsis</a>");
  }

  document.write(separator)

  if (active == "Genome") {
    document.write("Genome Initiative")
  }
  else {
    document.write("<a href=/info/agi.jsp>Genome Initiative</a>")
  }

  document.write(separator)

  if (active == "Nomenclature") {
    document.write("Nomenclature Guide")
  }
  else {
    document.write("<a href=/info/guidelines.jsp>Nomenclature Guide</a>")
  }

  document.write(separator)

  if (active == "Functional") {
    document.write("Functional Genomics")
  }
  else {
    document.write("<a href=/info/2010_projects/index.jsp>Functional Genomics</a>")
  }

  document.write(separator)

  if (active == "Monsanto") {
    document.write("Monsanto SNPs & Ler")
  }
  else {
    document.write("<a href=/Cereon>Monsanto SNPs & Ler</a>")
  }

  document.write(separator)

  if (active == "Expression") {
    document.write("Gene Expression")
  }
  else {
    document.write("<a href=/info/expression/index.jsp>Gene Expression</a>")
  }

  document.write(separator)

  if (active == "Education") { 
    document.write("Education & Outreach")
  }
  else {
    document.write("<a href=/info/education.jsp>Education & Outreach</a>")
  }

  document.write(separator)

  if (active == "Gene") {
    document.write("Gene Families")
  }
  else {
    document.write("<a href=/info/genefamily/genefamily.html>Gene Families</a>")
  }

  document.write(separator)

  if (active == "genesymbols") {
    document.write("Gene Class Symbols")
  }
  else {
    document.write("<a href=/jsp/processor/genesymbol/symbol_main.jsp>Gene Class Symbols</a>")
  }

  document.write(separator)

  if (active == "Ontologies") {
    document.write("Ontologies")
  }
  else {
    document.write("<a href=/info/ontologies>Ontologies</a>")
  }

  document.write(separator)

  if (active == "Marker") {
    document.write("Data Submission")
  }
  else {
    document.write("<a href=/submit/index.jsp>Data Submission</a>")
  }

  document.write(separator)

  if (active == "Arabidopsis") {
    document.write("Arabidopsis Labs")
  }
  else {
    document.write("<a href=/info/lab.jsp>Arabidopsis Labs</a>")
  }

  document.write(separator)

  if (active == "Techniques") {
    document.write("Protocols & Manuals")
  }
  else {
    document.write("<a href=/info/protocols.jsp>Protocols & Manuals</a>")
  }

  document.write(separator)

  if (active == "Electric") {
    document.write("Electronic Journals")
  }
  else {
    document.write("<a href=/browse/electricarab.jsp>Electronic Journals</a>")
  }

  document.write("</span>")
}


