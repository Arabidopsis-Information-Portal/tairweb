function educationSidebar(active) {
 document.write('<div id="leftcolumn">');
				  document.write('<ul id="leftnav">' );
                                                if (active == "Programs") {
                                                  document.write('<li class="selected"><a href="programs.jsp">Science Education Programs<\/a><\/li> ');
                                                  } else {
                                                  document.write('<li><a href="programs.jsp">Science Education Programs<\/a><\/li> ');
                                                  }
						if (active=="Outreach") {
						document.write('<li class="selected"><a href="outreach2.jsp">NSF Outreach Requirements for Scientists<\/a><\/li>');
						} else {
						document.write('<li><a href="outreach2.jsp">NSF Outreach Requirements for Scientists<\/a><\/li>');						}
                                                document.write('<li><a href="http:\/\/www.plantgdb.org\/PGROP\/pgrop.php">NSF Plant Genome Outreach Portal<\/a><\/li> ');
                                                if (active == "Web") {
                                                  document.write('<li class="selected"><a href="online.jsp">Web Resources for Teachers\/Students<\/a><\/li> ');
                                                  } else {
                                                  document.write('<li><a href="online.jsp">Web Resources for Teachers\/Students<\/a><\/li> ');
                                                  }
						if (active=="Teach") {
						document.write('<li class="selected"><a href="teach.jsp">Plant Biology Teaching Resources<\/a><\/li>');
						} else {
						document.write('<li><a href="teach.jsp">Plant Biology Teaching Resources<\/a><\/li>');
						}
						if (active=="Mail") {
						document.write('<li class="selected"><a href="email.jsp">Email groups<\/a><\/li>');
						} else {
						document.write('<li><a href="email.jsp">Email groups<\/a><\/li>');
						}
			  document.write('<\/ul>');


  document.write('<\/div>');
}