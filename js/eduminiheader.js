
function eduminiheader(active) {

  document.write("<span class=minilinks>")
		
  var separator=" | "

  if (active == "Guide") { 
     document.write("Education Outreach Guide")
  }		
  else {
    document.write("<a href=outreach2.html>Education and  Outreach Guide for Researchers</a>")
  }

  document.write(separator)

  if (active == "Programs") {
    document.write("Programs")
  }
  else {
    document.write("<a href=programs.html>Education and Outreach Programs</a>")
  }

  document.write(separator)

  if (active == "Online") {
    document.write("Web Resources")
  }
  else {
   document.write("<a href=online.html>Web Resources</a>")
  }


  document.write(separator)
  if (active == "teach") {
    document.write("Resources for educators and students")
  }
  else {
   document.write("<a href=teach.html>Teacher/Student Resources</a>")
  }


  document.write(separator)

  if (active == "Email") {
    document.write("Email Groups")
  }
  else {
   document.write("<a href=email.html>Plant Biology Education Email Groups</a>")
  }  

  document.write("</span>")
}



