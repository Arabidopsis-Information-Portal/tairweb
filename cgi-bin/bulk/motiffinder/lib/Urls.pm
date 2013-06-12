package Urls;
use CGI qw(:standard);


sub clusterid_link{

    my $clusterid = shift;
    my ($base_url) = "http://genome-www4.stanford.edu/cgi-bin/ewing/queryCloneList.pl?queryByClusterid=1&clusterid=".$clusterid;
    
    return a({ -href => "$base_url", }, $clusterid );
}

sub genbank_nucleotide_entry{

    my ($uid) = shift;
    my ($base_url) = "http://www4.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=n&form=6&dopt=g&uid=".$uid;
    
    return a({ -href => "$base_url", }, $uid );
    
}

sub genbank_protein_entry{

    my ($uid) = shift;
    my ($base_url) = "http://www4.ncbi.nlm.nih.gov/htbin-post/Entrez/query?db=p&form=6&dopt=g&uid=".$uid;
    
    return a({ -href => "$base_url", }, $uid );
    
}

sub source_page{
    
    my ($cloneid) = shift;
    
    my ($base_url) ="http://genome-www4.stanford.edu/cgi-bin/SMD/source/sourceResult?option=CloneID&choice=cDNA&criteria1=".$cloneid;
    return a({ -href => "$base_url", }, $cloneid );
    
}

sub hyperlink_text{

    my ($text) = shift;
    
    $text =~ s/(gi\|)(\w+)/sprintf("%s%s", $1,&genbank_protein_entry($2))/eg;
    
    return $text;
}

sub spotHistory_link{

    my $suid = shift;
    
    my ($base_url) = "http://genome-www4.stanford.edu/cgi-bin/SMD/spotHistory.pl?state=parameters&login=no&suid=".$suid; 

     return a({ -href => "$base_url", }, img {src=>'http://genome-www4.stanford.edu/icons/spotHistoryIcon.jpg'} );


}


sub pfam_query{
    
    my $id = shift;
    my $protseq = shift;
    my ($base_url) = "http://pfam.wustl.edu/cgi-bin/nph-hmmsearch?evalue=1.0&protseq=".$protseq;
    return a( { -href=> "$base_url"} , $id);
}

1;

