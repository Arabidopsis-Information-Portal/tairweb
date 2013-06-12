//this file is used to check if a given user has cookies enables on their browser
//if they do not, an alert is shown, asking the user to enable cookies
function getCookie()
{
if (document.cookie.length>0) //if there is a cookie that is stored
  {
	//check to see if that's our specific cookie
  c_start=document.cookie.indexOf("cookie=")
  if (c_start!=-1)
    { 
    c_start=c_start + 1 
    c_end=document.cookie.indexOf(";",c_start)
    if (c_end==-1) c_end=document.cookie.length
    return unescape(document.cookie.substring(c_start,c_end))
    } 
  }
return ""
}


function setCookie(expiredays)
{
var value = Math.floor(Math.random()*11)
var exdate=new Date()
exdate.setDate(exdate.getDate()+expiredays)
document.cookie= "cookie=" +escape(value)+
((expiredays==null) ? "" : ";expires="+exdate.toGMTString())
}


function checkCookie()
{
setCookie(365)

var userCookie= getCookie()


if (userCookie==null || userCookie=="")
  {alert('Please enable your browser cookies.')}

} 
