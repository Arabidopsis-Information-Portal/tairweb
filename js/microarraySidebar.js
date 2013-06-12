function microarraySidebar(active) {
 document.write('<div id="leftcolumn">');
			  document.write('<ul id="leftnav">');
				  document.write('<li><a href="">Microarrays</a>');
    					  document.write('<ul> ');
						if (active == "Datasets") {
      						  document.write('<li class="selected"><a href="microarrayDatasetsV2.jsp">Public Datasets</a></li> ');
						  } else {
      						  document.write('<li><a href="microarrayDatasetsV2.jsp">Public Datasets</a></li> ');
						  }
						if (active == "Expression") {
      						  document.write('<li class="selected"><a href="microarrayExpressionV2.jsp">Data Mining Tools</a></li> ');
						  } else {
      						  document.write('<li><a href="microarrayExpressionV2.jsp">Data Mining Tools</a></li> ');
						  }						
						if (active == "Elements") {
      						  document.write('<li class="selected"><a href="microarrayElementsV2.jsp">Array Designs & Array Element Mapping</a></li> ');
						  } else {
     						  document.write('<li><a href="microarrayElementsV2.jsp">Array Designs & Array Element Mapping</a></li> ');
						  }
						if (active == "Facilities") {
      						  document.write('<li class="selected"><a href="microarrayFacilitiesV2.jsp">Microarray Facilities</a></li> ');
						  } else {
      						  document.write('<li><a href="microarrayFacilitiesV2.jsp">Microarray Facilities</a></li> ');
						  }
						if (active == "Software") {
      						  document.write('<li class="selected"><a href="microarraySoftwareV2.jsp">Data Analysis Tools</a></li> ');
						  } else {
      						  document.write('<li><a href="microarraySoftwareV2.jsp">Data Analysis Tools</a></li> ');
						  }
						if (active == "Standards") {
      						  document.write('<li class="selected"><a href="microarrayStandardsV2.jsp">Microarray Standards and User Groups</a></li>');
						  } else {
      						  document.write('<li><a href="microarrayStandardsV2.jsp">Microarray Standards and User Groups</a></li>');
 						  }     						
    					  document.write('</ul> ');
					  document.write('<li><a href="http://mpss.udel.edu/at?/">Massively Parallel Signature Sequencing</a></li>');
						if (active == "Localization") {
					  document.write('<li class="selected"><a href="localization.jsp">Protein/RNA Localization</a></li>');
						  } else {
					  document.write('<li><a href="localization.jsp">Protein/RNA Localization</a></li>');
						  }
						if (active == "Functional") {
					  document.write('<li class="selected"><a href="microarrayFunctionalV2.jsp">Functional Genomics Expression Projects</a></li>');
						  } else {
					  document.write('<li><a href="microarrayFunctionalV2.jsp">Functional Genomics Expression Projects</a></li>');
						  }
				  document.write('</li>');
			  document.write('</ul>');


  document.write('</div>');
}
