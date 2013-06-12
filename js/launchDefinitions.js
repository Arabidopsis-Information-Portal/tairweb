// Brings up a new Definitions window.
function launchDefinitions(id) {
	remote = window.open("/servlets/TairObject?type=definitions&id=" + id, 
	  "Glossary", 
	  "location=no,menubar=no,scrollbars=yes,status=no,resizable=yes,width=300,height=200");
	if (!remote.opener) {
		remote.opener = window;
	}
	remote.resizeTo(300, 200);     // Netscape 4 compatibility issue.
	remote.focus();
	return remote;
}

