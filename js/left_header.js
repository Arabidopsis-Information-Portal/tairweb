

if (helpfile == "") { helpfile = "/help/index.html"; }
document.write('<table width="617" border="0" cellspacing="0" cellpadding="0"> <tr> <td width=15><img src="/images/cleargif.gif"></td><td>');
document.write('<table width="602" border="0" cellspacing="0" cellpadding="0"> <tr> ');

document.write('<td width=100 valign="bottom"><a href="/index.jsp"><img src="/images/logosmall.gif" width="100" height="35" alt="TAIR logo" border=0></a></td>');
document.write('<td align="right" valign="bottom">');

document.write('<a href="/index.jsp"><img src="/images/navbar/home.gif" alt="" border="0" height="10" vspace="0"></a><img src="/images/navbar/upper_s.gif" alt="" border="0" height="10" vspace="0"><a href="/about/"><img src="/images/navbar/about.gif" alt="" border="0" height="10" vspace="0"></a><img src="/images/navbar/upper_s.gif" alt="" border="0" height="10" vspace="0"><a href="/sitemap.jsp"><img src="/images/navbar/sitemap.gif" alt="" border="0" height="10" vspace="0"></a><img src="/images/navbar/upper_s.gif" alt="" border="0" height="10" vspace="0"><a href="/contact/"><img src="/images/navbar/contact.gif" alt="" border="0" height="10" vspace="0"></a><img src="/images/navbar/upper_s.gif" alt="" border="0" height="10" vspace="0"><a href="', helpfile,'"><img src="/images/navbar/help.gif" alt="" border="0" height="10" vspace="0"></a><img src="/images/navbar/upper_s.gif" alt="" border="0" height="10" vspace="0"><a href="/servlets/Order?state=view"><img src=/images/navbar/order.gif border="0"></a><img src="/images/navbar/upper_s.gif" alt="" border="0" height="10" vspace="0"><a href="/servlets/Community?action=login"><img src="/images/navbar/login.gif" alt="" border="0" height="10" vspace="0"></a><img src="/images/navbar/upper_s.gif" alt="" border="0" height="10" vspace="0"><a href="/servlets/Community?action=logout"><img src="/images/navbar/logout.gif" alt="" border="0" height="10" vspace="0"></a></td> ');
document.write('</tr> <tr> <td colspan=2><img src="/images/cleargif.gif" width="100" height="2"></td> </tr> <tr> ');
document.write('<td colspan=2 bgcolor="#cccccc"><img src="/images/cleargif.gif" width="100" height="8"></td> </tr> <tr> ');
document.write('<td colspan=2><img src="/images/cleargif.gif" width="100" height="2"></td> </tr> </table> ');

document.write('<table width="602" border="0" cellspacing="0" cellpadding="0"> <tr> ');
document.write('<td valign="top"> ');

if (highlight ==1 || highlight=="db") 
{
   document.write('<a href="/servlets/Search?type=general&action=new_search"><img src="/images/navbar/tairdb_y.gif" name="lownav1" alt="" border=0></a> ');
}
else
{
   document.write('<a href="/servlets/Search?type=general&action=new_search" onMouseOver="turnOnR(\'lownav1\'); window.status = \'TAIR Database\'" onMouseOut="turnOffR(\'lownav1\')"><img src="/images/navbar/tairdb_g.gif" name="lownav1" alt="" border=0></a> ');
}
 
if (highlight ==2 || highlight=="tools" )
{
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/tools/"><img src="/images/navbar/tools_y.gif" name="lownav2" alt="" border="0"></a> ');
}
else
{ 
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/tools/" onMouseOver="turnOnR(\'lownav2\'); window.status = \'Analysis and Visualization Tools\'" onMouseOut="turnOffR(\'lownav2\')"><img src="/images/navbar/tools_g.gif" name="lownav2" alt="" border="0"></a> ');
}

if (highlight == 3 || highlight=="info") 
{
document.write('<img src="/images/navbar/lower_s.gif"><a href="/info/"><img src="/images/navbar/browse_y.gif" name="lownav3" alt="" border="0"></a>  ');
}
else
{
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/browse/" onMouseOver="turnOnR(\'lownav3\'); window.status = \'Arabidopsis Information\'" onMouseOut="turnOffR(\'lownav3\')"><img src="/images/navbar/browse_g.gif" name="lownav3" alt="" border="0"></a>  ');
}

document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/submit/index.jsp" onMouseOver="turnOnR(\'lownav8\'); window.status = \'Submit\'" onMouseOut="turnOffR(\'lownav8\')"><img src="/images/navbar/submit_g.gif" name="lownav8" alt="" border="0"></a>');

if (highlight ==4 || highlight=="news")
{
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/news/"><img src="/images/navbar/news_y.gif" name="lownav4" alt="" border="0"></a> ');
}
else
{
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/news/" onMouseOver="turnOnR(\'lownav4\'); window.status = \'TAIR News\'" onMouseOut="turnOffR(\'lownav4\')"><img src="/images/navbar/news_g.gif" name="lownav4" alt="" border="0"></a> ');
}

if (highlight ==5 || highlight=="links")
{
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/links/"><img src="/images/navbar/portals_y.gif" name="lownav5" alt="" border="0"></a> ');
}
else
{
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/links/" onMouseOver="turnOnR(\'lownav5\'); window.status = \'External Links\'" onMouseOut="turnOffR(\'lownav5\')"><img src="/images/navbar/portals_g.gif" name="lownav5" alt="" border="0"></a> ');
}

if (highlight ==6 || highlight=="ftp")
{
    document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="ftp://ftp.arabidopsis.org/home/tair/"><img src="/images/navbar/ftp_y.gif" name="lownav6" alt="" border="0"></a>  ');
}
else
{
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="ftp://ftp.arabidopsis.org/home/tair/" onMouseOver="turnOnR(\'lownav6\'); window.status = \'FTP\'" onMouseOut="turnOffR(\'lownav6\')"><img src="/images/navbar/ftp_g.gif" name="lownav6" alt="" border="0"></a>  ');
}
if (highlight ==7 || highlight=="stocks")
{
    document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/abrc"><img src="/images/navbar/stocks_y.gif" name="lownav7" alt="" border="0"></a>  ');
}
else
{
   document.write('<img src="/images/navbar/lower_s.gif" alt="" border="0"><a href="/abrc" onMouseOver="turnOnR(\'lownav7\'); window.status = \'Stocks\'" onMouseOut="turnOffR(\'lownav7\')"><img src="/images/navbar/stocks_g.gif" name="lownav7" alt="" border="0"></a>  ');
}
document.write('</td></tr> ');
document.write('<tr><td align="right" valign="top"> ');
function valueSubmit(value, form, form_query_var) {
    if (form.action) {
        form_query_var.value = value;
        form.submit();
        return false;
    }
    return true;
}
document.write('<table><tr><td valign="bottom"><form name="search_textbox_form" onSubmit="return document.search_choice.onsubmit()"><input name="textbox" type="text" size="10"></form></td><td valign="bottom"><FORM name="google_form" method="GET" action="http://www.google.com/custom"><INPUT TYPE=hidden name=q size=10 maxlength=255 value=""><INPUT type=hidden name=cof VALUE="L:http://www.arabidopsis.org/images/logosmall.gif;AH:left;GL:0;S:http://www.arabidopsis.org;AWFID:56b9e4624af96ab2;"><input type=hidden name=domains value="arabidopsis.org"><input type=hidden name=sitesearch value="arabidopsis.org"></FORM><form name="tairdb_form" action="/servlets/Search" method="post"><input type="hidden" name="type" value="general"><input type="hidden" name="action" value="search"><input type="hidden" name="method" value="4"><input type="hidden" name="name" size="10"></form> ');
function doSearch(choice) {
    if (choice == "db") {
        return valueSubmit(document.search_textbox_form.textbox.value,
                           document.tairdb_form,
                           document.tairdb_form.name)
    }
    else if (choice == "site") {
        return valueSubmit(document.search_textbox_form.textbox.value,
                           document.google_form,
                           document.google_form.q)
    }
    return false;
}
document.write('<form name="search_choice" onSubmit="return doSearch(document.search_choice.choice.options[document.search_choice.choice.selectedIndex].value)"><select name="choice"><option value="db" selected>TAIR Database</option><option value="site">TAIR Website</option></select><input type="submit" value="Quick Search"></form></td></tr></table></td></tr></table>');


document.write('</td> </tr> </table> ');
document.write('</td> </tr> </table> ');

