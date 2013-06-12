function helpSidebar(active) {
 document.write('<div id="leftcolumn">')
			  document.write('<ul id="leftnav">');
				  document.write('<li><a href="">Tutorials</a>');
    					  document.write('<ul> ');
      						  document.write('<li><a href="tutorials/go_intro.jsp">GO Annotation</a></li> ');
      						  document.write('<li><a href="tutorials/aracyc_intro.jsp">AraCyc Metabolic Pathways</a></li> ');
     						  document.write('<li><a href="tutorials/micro_intro.jsp">Finding Microarray Data at TAIR</a></li> ');
    					  document.write('</ul> ');
						if (active == "Quickstart") {
					  document.write('<li class="selected"><a href="quickstart.jsp">Getting Started at TAIR</a></li>');
						  } else {
					  document.write('<li><a href="quickstart.jsp">Getting Started at TAIR</a></li>');
						  }
						if (active == "Faq") {
					  document.write('<li class="selected"><a href="faq.jsp">Frequently Asked Questions</a></li>');
						  } else {
					  document.write('<li><a href="faq.jsp">Frequently Asked Questions</a></li>');
						  }
                                                if (active == "Help") {
                                          document.write('<li class="selected"><a href="helpcontents.jsp">Database/Tool Help Pages</a></li>');
                                                  } else {
                                          document.write('<li><a href="helpcontents.jsp">Database/Tool Help Pages</a></li>');
                                                  }
				document.write('<li><a href="\/servlets\/processor?type=definition&update_action=glossary">TAIR Glossary<\/a><\/li>');
				  document.write('</li>');
			  document.write('</ul>');


  document.write('</div>');
}
