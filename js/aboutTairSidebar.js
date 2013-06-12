function aboutTairSidebar(acitve) {
 document.write('<div id="leftcolumn">');
			  document.write('<ul id="leftnav">');
				if (active == "TAIRStaff") {
				  document.write('<li class="selected"><a href="/about/staff.jsp">TAIR Staff</a></li>');
				} else {
				  document.write('<li><a href="/about/staff.jsp">TAIR Staff</a></li>');
				}
				  document.write('<li><a href="http://www.biosci.ohio-state.edu/~plantbio/Facilities/abrc/person.htm">ABRC Staff</a></li>');
				if (active == "TAIRData") {
				  document.write('<li class="selected"><a href="/about/datasources.jsp">TAIR data sources</a></li>');
				} else {
				  document.write('<li><a href="/about/datasources.jsp">TAIR data sources</a></li>');
				}
				if (active == "LinktoTAIR") {
				  document.write('<li class="selected"><a href="/about/linktotair.jsp">Hyperlinking to TAIR</a></li>');
				} else {
				  document.write('<li><a href="/about/linktotair.jsp">Hyperlinking to TAIR</a></li>');
				}
				if (active == "citingTAIR") {
				  document.write('<li class="selected"><a href="/about/citingtair.jsp">Citing TAIR</a></li>');
				} else {
				  document.write('<li><a href="/about/citingtair.jsp">Citing TAIR</a></li>');
				}
				if (active == "Proposal") {
				  document.write('<li class="selected"><a href="/about/proposal.jsp">Proposal</a></li>');
				} else {
				  document.write('<li><a href="/about/proposal.jsp">Proposal</a></li>');
				}
				  document.write('<li><a href="/search/schemas.html">TAIR Database Schema & Documentation</a></li>');

				if (active == "TAIRPubs") {
				  document.write('<li class="selected"><a href="/about/tairpubs.jsp">Publications</a></li>');
				} else {
				  document.write('<li><a href="/about/tairpubs.jsp">Publications</a></li>');
				}
				if (active == "FuturePlans") {
				  document.write('<li class="selected"><a href="/about/futureplans.jsp">Future Projects</a></li>');
				} else {
				  document.write('<li><a href="/about/futureplans.jsp">Future Projects</a></li>');
				}
				if (active == "Software") {
				  document.write('<li class="selected"><a href="/about/software.jsp">TAIR Software</a></li>');
				} else {
				  document.write('<li><a href="/about/software.jsp">TAIR Software</a></li>');
				}
				  document.write('<li><a href="/jsp/tairjsp/pubDbStats.jsp">TAIR Database Statistics</a></li>');
				  document.write('<li><a href="/usage/">TAIR Usage Statistics</a></li>');
				  document.write('<li><a href="TAIRUserGuideV1.0.pdf">Users Guide(pdf)</a></li>');
			  document.write('</ul>');


  document.write('</div>');
}