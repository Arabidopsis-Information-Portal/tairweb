function newsminiheader(active) {

  document.write("<span class=minilinks>")
		
  var separator=" | "

  if (active == "TAIR News") { 
     document.write("TAIR News")
  }		
  else {
    document.write("<a href=/news/news.jsp>TAIR News</a>");
  }

  document.write(separator)

  if (active == "Newsgroup") {
    document.write("Arabidopsis Newsgroup")
  }
  else {
    document.write("<a href=/news/newsgroup.jsp>Newsgroup</a>")
  }

  document.write(separator)

  if (active == "Jobs") {
    document.write("Job Postings")
  }
  else {
    document.write("<a href=/news/jobs.jsp>Job Postings</a>")
  }

  document.write(separator)

  if (active == "Events") {
    document.write("Conferences and Events")
  }

  else {
    document.write("<a href=/news/events.jsp>Confs & Events</a>")
  }

  document.write("</span>")
}


