

function genhelpheader(active) {

  document.write("<span class=minilinks>")
		
  var separator=" | "

  if (active == "QuickStart") { 
     document.write("Getting started using TAIR")
  }		
  else {
    document.write("<a href=/help/quickstart.jsp>TAIR QuickStart</a>")

  }
  document.write(separator)


  if (active == "faq") {
    document.write("Frequently Asked Questions")
  }
  else {
    document.write("<a href=/help/faq.jsp>Frequently Asked Questions</a>")
  }

  document.write(separator)

  if (active == "helpcontents") {
    document.write("Database/Tool Help Pages")
  }
  else {
   document.write("<a href=/help/helpcontents.jsp>Database Search and Tool Help Pages</a>")
  }  

 document.write(separator)

  if (active == "glossary") {
    document.write("TAIR Glossary")
  }
  else {
   document.write("<a href=/servlets/processor?type=definition&update_action=glossary>TAIR Glossary</a>")
  }

  document.write("</span>")
}



