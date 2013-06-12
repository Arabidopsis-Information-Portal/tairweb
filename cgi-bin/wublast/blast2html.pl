#!/bin/env perl

#<TITLE>blast2html.pl -- BLAST to HTML filter</TITLE><PRE>
#<H1>BLAST to HTML</H1>
#<a href="http://golgi.harvard.edu/blast2html.pl">Current Version</a>
# blast2html -- converts output from NCBI Network BLAST server
#               to HTML hypertext
#               Keith Robison  November 1993     
#		<a href="http://golgi.harvard.edu/gilbert.html">Gilbert Lab</a> 
#		<a href="http://golgi.harvard.edu">Harvard Biolabs</a>
#	        krobison@nucleus.harvard.edu
#
#  HTML Markups
#  
#  1) Database accession numbers are links to retrieve database entriesST
#  2) Poisson score in top summary is a link to alignment
#  3) Angle bracket at start of alignment description is link back to summary
#
#  Citation:
#   Robison, K.  A simple hypertext BLAST output browsing scheme.   
#   Unpublished.
#
#  Freedom to use and modify this program is granted so long as the 
#  citation above remains intact and modifications are documented.
#  
#
# Modified quite alot by J.M.Cherry for the SGD BLAST server. July 30,1995
#
# Modified by Bengt Anell Januari, 2001
# Links to work with TAIR datasets
#
# Modified by Guanghong Chen March, 2002
# 1. Turn this into a library instead of a executable, so that a system call 
#    is saved. 
# 2. Change into the right format, so the sequences can align correctly.

#</PRE>
#<LISTING>

# WWW link stems for databases
# copied from TAIR NCBI blast CGI code

use strict 'vars';

my $GB_NT_old = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?" .
  "cmd=Search&db=Nucleotide&doptcmdl=GenBank&term=";

my $GB_NT_EST = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nucest&id=';
my $GB_NT_CORE = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nuccore&id=';
#http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=nuccore&id=42470403
my $GenPept_old = 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?' .
  'cmd=Search&db=Protein&doptcmdl=GenPept&term=';

my $GenPept = 'http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=protein&id=';

#taken from NCBI blast version
my $GenPeptNCBI =
   'http://www.ncbi.nlm.nih.gov:80/entrez/query.fcgi?'
  .'cmd=Retrieve&db=Protein&dopt=GenPept&list_uids=';

$GenPeptNCBI = $GenPept;

my $TIGR = "http://www.tigr.org/tigr-scripts/euk_manatee/shared/" .
  "ORF_infopage.cgi?db=ath1&orf=";
my $TIGR_BAC = "http://www.tigr.org/tigr-scripts/euk_manatee/" .
  "BacAnnotationPage.cgi?db=ath1&asmbl_id=";
my $MIPS = 'http://mips.gsf.de/cgi-bin/proj/thal/search_gene?code=';   
my $SEED_DETAIL = "/servlets/SeedSearcher?action=detail&stock_number=";
my $LOCUS_DETAIL = "/servlets/TairObject?type=locus&name=";
my $CLONE_DETAIL = "/servlets/TairObject?type=clone&name=";
my $ASSEMBLY_UNIT_DETAIL = "/servlets/TairObject?type=assembly_unit&name=";
my $UNIPROT = "http://www.uniprot.org/entry/";

my $FoundTable = 0;



sub convert($$)
{
    my ( $blastResult ) = shift;
    my ( $database ) = shift;

    # define GenBank db (NT vs. protein) to use
    # for links based on database ( grep {/$database/} @aaDbNames ) 
    my $GB_LINK;
    if($database  =~ /AA/) #eq "PlantProtein")
    {
	    $GB_LINK = $GenPeptNCBI
    }
    elsif ($database =~ /mrna|genomic|refseq/i) {  #eq "ATH1_pep" or $database eq "ArabidopsisP" ) {
	$GB_LINK = $GB_NT_CORE; #$GenPept;
    } else {
	$GB_LINK = $GB_NT_EST;
    }
  
    my ( $firstResult ) = 0;
  
    print( "<table width=\"700\" border=\"1\" " .
           "cellpadding=\"1\"><tr><td>" ); 

    print( "<P>" );
    print( "<h1><A HREF=\"http://blast.wustl.edu/blast/" .
           "README.html\"> WU-BLAST 2.O </A>query on <i>Arabidopsis</i> " .
           "sequences</h1>" );
    print( "<b>Query performed by " );
    print( "<A HREF=\"http://www.arabidopsis.org/\">TAIR </A>; \n" );
    print( "for full BLAST options and parameters, refer to the<A " .
           "HREF=\"http://www.ncbi.nlm.nih.gov/BLAST/blast_help.html\"> " .
           "BLAST Documentation at NCBI</A>\n" );
    print( "</b><P>\n" );
    print( "Links to <b>GenBank</b> are provided within the document; \n" );
    print( "links to locations within this document are provided from the " .
           "<b>graphics</b> above.\n" );
    print( "<p>Your comments and suggestions are requested: " );
    print( "<a href=\"http://arabidopsis.org/contact.html\">Contact " .
           "TAIR</a>" ); 
    print( "<hr>\n" );
    print( "<font face =\"courier\">" ); 
  
    open( BLAST_RESULT, "$blastResult" ) 
        or die "Can't open file $blastResult: $!";
  
    while ( <BLAST_RESULT> )
    { 
        chomp;
        if ( m/^Filtering On/ ) 
        {
            print( "<h3>Please Note Sequence Filtering is ON.</h3>" );
            print( "Sequence filtering will mask out regions with low " .
                   "compositional complexity or segments consisting of " .
                   "simple repetitive sequences from your query sequence. " );
            print( "Filtering can eliminate statistically significant but " .
                   "biologically uninteresting reports from the BLAST " .
                   "output. " );
            print( "A low complexity sequence found by a filter program is " .
                   "substituted using the letter \"N\" in nucleotide " .
                   "sequence (e.g., \"NNNNN\") and the letter \"X\" in " .
                   "protein sequences (e.g., \"XXXXX\"). " );
            print( "Filtering is on by default, however it can be turned " .
                   "off by selecting \"none\" from the <b>Filter options" .
                   "</b> on the BLAST form.<p>" );
            print( "For more details on filtering see the <a href=\"" .
                   "http://www.ncbi.nlm.nih.gov/BLAST/blast_help.html\">" .
                   "BLAST Help at NCBI.</a><hr>" );
        }
    
        if ( m/^TBLAST/ || m/^BLAST/ ) 
        {
            if ( $firstResult )
            {
                print( "</PRE>\n" );
            }

            $firstResult = 1;

            s%(\S+)\s+(.*)%<B>$1</B> $2<br>%o;
            print( "$_" );
            print( "<p><b>References:</b><dl>" );
            print( "<dd><li>Altschul, Stephen F., Gish, Warren, \n" );
            print( "Miller, Webb, Myers, Eugene W., and David J. Lipman " .
                   "(1990). Basic \n" );
            print( "local alignment search tool. <i>J. Mol. Biol.</i> " .
                   "<b>215</b>:403-410. \n" );
            print( "[<a href=\"http://www4.ncbi.nlm.nih.gov/htbin-post/" .
                   "Entrez/query?uid=2231712&form=6&db=m&Dopt=r\">" .
                   "PubMed</a>]<br>\n" );
            print( "<dd><li>Gish, Warren, and David J. States (1993). " .
                   "Identification of protein coding regions by database " .
                   "similarity search. <i>Nature Genetics</i> <b>3</b>:" .
                   "266-72. [<a href=http://www.ncbi.nlm.nih.gov/htbin-post/" .
                   "Entrez/query?uid=8485583&form=6&db=m&Dopt=r>PubMed</a>]" .
                   "<br>\n" );
            print( "<dd><li>Gish, Warren (1994) unpublished. " .
                   "<a href=http://blast.wustl.edu>BLAST2 Documentation" .
                   "</a></dl><p>" );
        } 
        elsif ( m/^Query=/ ) 
        {
            #s%Query= *(.*)%<title>$1</title>\n<p><b>Query Sequence:</b>  $1%o;
            s%Query= *(.*)%<p><b>Query Sequence:</b>  $1%o;
            print( "$_\n" );

            while ( m/\S+/ ) 
            {
                $_ = <BLAST_RESULT>;
                if ( m/\d+ letters/ )
                {
                    print( "<BR><B>Length:</B> $_\n" );
                }
                else
                {
                    print( "$_\n" );
                }
            }
        }
        elsif ( m/^Notice:/ ) 
        {
            s%Notice: *(.*)%<p><b>Notice:</b> $1%o;
            print( "$_\n" );

            while ( m/\S+/ ) 
            {
                $_ = <BLAST_RESULT>;
                print( "$_\n" );
            }
        } 
        elsif ( /^Database:/ ) 
        {
            $_ =~ s%ATH1_seq%Genes from AGI, Total Genome (DNA);%;
            $_ =~ s%ATH1_cds%CDS from AGI, Total Genome (DNA);%;
            $_ =~ s%ATH1_pep%Proteins from AGI, Total Genome (Protein);%;
            $_ =~ s%ATH1_bacs_con%TIGR AGI BAC Sequences (DNA);%;  
            $_ =~ s%AGI_BAC%GenBank AGI BAC Sequences (DNA);%;
            $_ =~ s%ArabidopsisN%GenBank, including ESTs & BAC ends (DNA);%;
            $_ =~ s%AtANNOT%GenBank, minus ESTs & BAC ends (DNA);%;
            $_ =~ s%ArabidopsisP%GenPept, PIR, &amp; SwissPROT (Protein);%;
            $_ =~ s%recent_at%New GenBank (DNA) ;%;
            $_ =~ s%AtBACEND%GenBank and Kazusa BAC Ends(DNA);%;
            $_ =~ s%AtEST%GenBank ESTs (DNA);%;
            $_ =~ s%TDNA%Insertion Flank Sequences (DNA);%;
            $_ =~ s%PlantDNA%All Higher Plant Sequences (DNA);%;
            $_ =~ s%At_upstream_1000%Loci Upstream Sequences - 1000bp;%;
            $_ =~ s%At_upstream_3000%Loci Upstream Sequences - 3000bp;%;
            $_ =~ s%At_downstream_1000%Loci Downstream Sequences - 1000bp;%;
            $_ =~ s%At_transcripts%AGI Transcripts;%;
            $_ =~ s%uniprot%Uniprot Plant Proteins;%;
     
            s%Database: *(.*)%<p><b>Database:</b> $1%o;

            print( "$_<BR>\n" );

        } 
        elsif ( /^WARNING:/ ) 
        {
            s%WARNING: *(.*)%<p><b>Warning:</b> $1%o;
            print( "$_<BR>\n" );

            while ( m/\S+/ ) 
            {
                $_ = <BLAST_RESULT>;
                print( "$_</p><BR>\n" );
            }
        } 
        elsif ( /Smallest$/ ) 
        {
            $FoundTable = 1;
      
            print( "<font face =\"courier\">" );  
            print( "<p><pre>\n" );
        }

        if ( $FoundTable == 1 ) 
        {
		#print "$_\n";
            # Beginning of report body stuff -- title, 'pre-formatted' instruction
            # generate section markers at alignment
      
            # TIGR

            # Matches dataset - ATH1_cds, ATH1_seq, ATH1_pep
# TIGR|MIPS|TAIR|At3g45780|F16L2.3 T6D9.110 nonphototropic ...   845  0.        1
# TIGR|MIPS|TAIR|At3g45780|F16L2.3 T6D9.110 nonphototropic ...   845  7.1e-33   1
# TIGR|MIPS|TAIR|At5g18660|T1A4.40  putative protein 2'-hyd...   177  0.015     1
# TIGR|MIPS|TAIR|At5g53040|MNB8.10  putative protein simila...   138  0.56      1

            if ( m%(TIGR)\|(MIPS)\|(TAIR)\|% )
            {
                s%^(TIGR)\|(MIPS)\|(TAIR)\|(.*?)\|(.*?) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%<A NAME="$2\/$3|$4|$5_H"></A><b><a href= "$TIGR$4" target=_new>$1</A>\|<a href="$MIPS$4" target=_new>$2</A>\|<a href="$LOCUS_DETAIL$4" target=_new>$3</A>\|$4</b>$5 $6 <a href="#$2\/$3|$4|$5_A" >$7</A> $8%o;
                s%^>(TIGR)\|(MIPS)\|(TAIR)\|(.*?)\|(.*?) %><A NAME="$2\/$3|$4|$5_A"></A><b><a href="$TIGR$4" target=_new>$1</a>|<a href="$MIPS$4" target=_new>$2</a>|<a href="$LOCUS_DETAIL$4" target=_new>$3</a></b>|$4|$5 %o;	
            }

            #
            # Matches TDNA insertion flank sequences  - targetSet = TDNA
            #
# Stock|CS100256 SequenceName|SGT6752-3-3.txt                    125  0.42      1
# Stock|SALK_007402 GB|BH212302 Locus|                           124  0.53      1
# Stock|SALK_005579 GB|BH172346                                  127  0.44      1
# Stock|SALK_010903 GB|BH251043 Locus|At5g18940 (an annotat...   122  0.59      1

            #new format, put Stock|SAL.. in the next column
#>GB|BH616909 Stock|SALK_035651 Locus|
#>GB|BH616910 Stock|SALK_035652 Locus|At3g01200 (an annotated exon)
#>GB|BH616913 Stock|SALK_035655 Locus|
#>GB|BH616933 Stock|SALK_035682 Locus|At5g43760 (300 bases of the 3' end), At5g43770 (300 bases of
# the 5' end)
#>SequenceName|GT2577-3-2.txt Stock|CS100338
#3>SequenceName|GT2577-3-3c.txt Stock|CS100338

            if ( m%Stock|% )
            {

                s%^(SequenceName\|)(\S+) (Stock\|)(\S+) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%<A NAME="$2_H"></A>$1$2 $3<b><a href= "$SEED_DETAIL$4" target=_new>$4</A></b> $5 <a href="#$2_A">$6</A> $7%o;
                s%^(GB\|)(\S+) (Stock\|)(\S+) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%<A NAME="$2_H"></A>$1<b><a href="$GB_LINK$2" target=_new>$2</A></b> $3<b><a href= "$SEED_DETAIL$4" target=_new>$4</A></b> $5 <a href="#$2_A">$6</A> $7%o;
                s%^>(SequenceName\|)(\S+) (Stock\|)(\S+)%><A NAME="$2_A"></A>$1$2 $3<b><a href= "$SEED_DETAIL$4" target=_new>$4</A></b>%o;
                s%^>(GB\|)(\S+) (Stock\|)(\S+)%><A NAME="$2_A"></A>$1<b><a href="$GB_LINK$2" target=_new>$2</A></b> $3<b><a href= "$SEED_DETAIL$4" target=_new>$4</A></b>%o;	
                s%(Locus\|)(\S+)(\s)%$1<b><a href=\"$LOCUS_DETAIL$2\" target=_new>$2</a></b>$3%o;
            }

            #
            #
            # Matches TIGR BACS dataset=ATH1_bacs_con ###
#   T6D9 67250                                           765  2.3e-28   1
#   F16L2 67251                                          765  2.3e-28   1
#   F20D22 51021                                         149  0.78      1
#   F16B3 60284                                          147  0.85      1
#   F17O14 60265                                         145  0.90      1

            if ( $database eq "ATH1_bacs_con" && /^>?(\w+)\s*(\d{5})/ ) 
            {
                s%^(\w+)(\s*)(\d{5}) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%<A NAME="$1_H"></A><b><a href="$ASSEMBLY_UNIT_DETAIL$1" target=_new>$1</A></b>$2<b><a href="$TIGR_BAC$3" target=_new>$3</A></b> $4 <a href="#$1_A">$5</A> $6%o;
                s%^>(\w+)(\s*)(\d{5})%<A NAME="$1_A"></A><b><a href="$ASSEMBLY_UNIT_DETAIL$1" target=_new>$1</A></b>$2<b><a href="$TIGR_BAC$3" target=_new>$3</A></b>%o;
            }

            ### Matches Uniprot dataset = uniprot ###
            # Q56Y57_ARATH (Q56Y57) Nonphototropic hypocotyl 1 (Fragmen...   124  2.5e-06   1
            # PHOT1_ARATH (O48963) Phototropin-1 (EC 2.7.1.37) (Non-pho...   124  3.7e-06   1
            # Q6S6M0_9MAGN (Q6S6M0) AGAMOUS-like protein (Fragment) - N...    63  0.81      1
            if ( $database eq "At_Uniprot_prot" && /^>?(\w+)\s*\|\s*(\w+)/ ) {

                # replace uniprot id with hyperlink to page
                my $uniprot_id = $2;
                my $url =  "<a href=\"$UNIPROT$uniprot_id\" target=_new>$uniprot_id</a>";
                      
                $_ =~ s/$uniprot_id/$url/;
   
                # if score is in line, must be in summary - make score link to
                # anchor down below
                if ( /(\d[0-9e\-\.]{0,}) ( *\d*)$/ ) {
                    my $score = $1;
                    my $anchor = "<A HREF=\"#$uniprot_id" . "_A\">$score</A>";
                    $_ =~ s/$score/$anchor/;
                    
                # if no score in line, must be down below so print anchor
                } elsif ( $_ =~ /^>/ ) {
                    my $anchor = "<A NAME=$uniprot_id" . "_A></A>";
                    $_ = $anchor . $_;
                }
            }
#print "OUT|||$_\n";
	    if(m%^>?gi\|(\d+)\|%)
	    {
		#gi|18423463 ref|NM_124683.1| Arabidopsis thaliana chromos...   138  0.995     1
		    #s%^(\w+\|)(.*?)\|(.*?) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%$1<A NAME="$2_H"></A><b><a href= "$GB_LINK$2" target=_new>$2</A></b>|$3 $4 <a href="#$2_A">$5</A> $6%o;
		    #s%^(>\w+\|)(.*?)\|(.*?) %<A NAME="$2_A"></A>$1<b><a href= "$GB_LINK$2" target=_new>$2</A></b> %o;

		#TDNA: >gi|56095545|gb|CW839755|GT8795.DS3.03.05.2002.JW17.499

                s%^(>?gi\|)(\d+)(\|\w+\|.*\|)(\s*)(\w+)(\s*.*\s+)(\d+[\.\d+e\-]{0,})(\s+\d+)$%$1<A NAME="$2_H"></A><b><a href= "$GB_LINK$2" target=_new>$2</A></b>$3$4$5$6<a href="#$2_A">$7</A>$8%o;
		    s%^(>?gi\|)(\d+)\|%<A NAME="$2_A"></A>$1<b><a href= "$GB_LINK$2" target=_new>$2|</A></b>%o;
		    #s%^(>gi\|)(\d+)%<A NAME="$2_A"</A>$1<b><a href= "$GB_LINK$2" target=_new>$2</A></b>%o;
	    }
            # PlantDNA 
#GSDB:S:2155815|AF030864|AF030864|Arabidopsis thaliana non...  1160  1.0e-45   1
#GSDB:S:470642|W43664|W43664|23057 CD4-16 Arabidopsis thal...  1145  1.9e-45   1
#GSDB:S:11560113|AF360218|AF360218|Arabidopsis thaliana pu...   920  9.0e-35   1
      
            #
            # GSDB Format Link to Genbank
            # >GSDB:S:11439|L13922|ATHAXR1122|Arabidopsis thal

            if ( m%DISABLED|GSDB\:S\:(.*?)\|(.*?)\|(.*?)% ) 
            {

                s%^GSDB\:S\:(.*?)\|(.*?)\|(.*?)\|(.*?) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)%<A NAME="S/$1\|$2\|$3|\$4_H"></A>GenBank|<b><a href="$GB_LINK$2" target=_new>$2</A></b>|$3|       $4 $5 <a href="#S/$1\|$2\|$3\|$4_A">$6</A> $7%o;
                s%^>GSDB\:S\:(.*?)\|(.*?)\|(.*?)\|(.*?) %<A NAME="S/$1\|$2\|$3\|$4_A"></A>>GenBank|<b><a href="$GB_LINK$2" target=_new>$2</A></b>|$3|$4 %o;
            }
       
            #
            #
            # Matches AGI BACS dataset=AGI_BAC ###
#emb|AL162459.2|ATF16L2 Arabidopsis thaliana DNA chromosom...   925  1.3e-35   1
#dbj|AB010693.1|AB010693 Arabidopsis thaliana genomic DNA,...   137  0.993     1
#gb|AF002109.2|AF002109 Arabidopsis thaliana chromosome II...   137  0.993     1

            #recent_at, 
#gi|15237134 ref|NC_003076.1| Arabidopsis thaliana chromos...   177  0.044     1
#gb|AY065129.1| Arabidopsis thaliana unknown protein (At3g...   145  0.68      1
#dbj|AB073153.1|AB073153 Arabidopsis thaliana DNA, chromos...   142  0.82      1
#ref|NC_003074.1| Arabidopsis thaliana chromosome 3, compl...   635  9.2e-23   1

            # AtBACEND, 
#emb|AL082779.1|CNS00O59 Arabidopsis thaliana genome surve...   142  0.38      1

            #AtEST, 
#gb|W43664.1|W43664 23057 CD4-16 Arabidopsis thaliana cDNA...  1145  8.5e-47   1
#gb|AV529038.1|AV529038 AV529038 Arabidopsis thaliana abov...   870  1.8e-34   1

            #ArabidopsisN
#emb|AL162459.2|ATF16L2 Arabidopsis thaliana DNA chromosom...   925  3.1e-35   1
#gb|AV529038.1|AV529038 AV529038 Arabidopsis thaliana abov...   870  1.2e-33   1
#gi|18408071 ref|NM_114447.1| Arabidopsis thaliana chromos...   845  6.6e-32   1
#dbj|AB073153.1|AB073153 Arabidopsis thaliana DNA, chromos...   142  0.9993    1
      
            #AtANNOT
#gb|AF360218.1|AF360218 Arabidopsis thaliana putative nonp...   920  1.8e-35   1
#emb|AL157735.2|ATT6D9 Arabidopsis thaliana DNA chromosome...   925  2.2e-35   1
#dbj|AB073153.1|AB073153 Arabidopsis thaliana DNA, chromos...   142  0.994     1
#gi|18423463 ref|NM_124683.1| Arabidopsis thaliana chromos...   138  0.995     1

            #brassica
#gb|AF527947.1| Brassica oleracea homeodomain protein BOST...  1650  3.3e-90   2
#gb|AF193813.2|AF193813 Brassica oleracea shoot meristemle...  1581  9.8e-87   2
#gb|L38536.1|L38536 BNAF0175E Mustard flower buds Brassica...  1477  4.2e-61   1
#gb|BH509295.1|BH509295 BOGZQ65TF BOGZ Brassica oleracea g...   195  0.62      1
	    #PlantProtein 
	    #>gi|47827214|dbj|BAD20774.1| beta-galactosidase [Raphanus sativus]  1650	3.3e-90	2


            if ( 1==0 && m%(gb)\|(.*?)(\|.*)% || 
                 m%(dbj)\|(.*?)(\|.*)% || 
                 m%(emb)\|(.*?)(\|.*)% || 
	 	 m%(pir)\|(.*?)(\|.*)%  ||
	  	 m%(sp)\|(.*?)(\|.*)% )
            {
                if ( m%(\w+\|)(.*?)\|(.*?) ( *.*)% )
                {
                    if ( $3 eq "" )
                    {
			    #print "if $_\n";
                        s%^(\w+\|)(.*?)\|(.*?) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%$1<A NAME="$2_H"></A><b><a href= "$GB_LINK$2" target=_new>$2</A></b>|$3 $4 <a href="#$2_A">$5</A> $6%o;
                        s%^(>\w+\|)(.*?)\|(.*?) %<A NAME="$2_A"></A>$1<b><a href= "$GB_LINK$2" target=_new>$2</A></b> %o;	
                    }
                    else 
                    {
			    #print "ELSE $_\n";
                        s%^(\w+\|)(.*?)\|(.*?) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%$1<A NAME="$2/$3_H"></A><b><a href= "$GB_LINK$2" target=_new>$2</A></b>|$3 $4 <a href="#$2/$3_A">$5</A> $6%o;
                        s%^(>\w+\|)(.*?)\|(.*?) %<A NAME="$2/$3_A"></A>$1<b><a href= "$GB_LINK$2" target=_new>$2</A></b> %o;
                    }
                }
            }

#ref|NC_003074.1| Arabidopsis thaliana chromosome 3, compl...   635  9.2e-23   1

            if ( m%(DISABLEDref)\|(.*?)(\|.*)% )
            {
		    #print "ref  $_\n";

                s%^(\w+\|)(.*?)\|(.*?) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%$1<A NAME="$2_H"></A><b><a href= "$GB_LINK$2" target=_new>$2</A></b>|$3 $4 <a href="#$2_A">$5</A> $6%o;
                s%^(>\w+\|)(.*?)\|(.*?) %<A NAME="$2_A"></A>$1<b><a href= "$GB_LINK$2" target=_new>$2</A></b> %o;
            }

#gi|18423463 ref|NM_124683.1| Arabidopsis thaliana chromos...   138  0.995     1

            if ( m%(DISABLEDgi)\|(\d+) ( *.*)% )
            {
		    #print "later gi $_\n";

                s%^(gi\|)(\d+) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%<A NAME="$2_H"></A>$1<b><a href= "$GB_LINK$2" target=_new>$2</A></b> $3 <a href="#$2_A">$4</A> $5%o;
                s%^(>gi\|)(\d+)%<A NAME="$2_A"</A>$1<b><a href= "$GB_LINK$2" target=_new>$2</A></b>%o;
            }
      
            #
            # Matches At_upstream_1000 At_upstream_3000, At_downstream_1000, 
            # At_downstream_3000
            #
            
#AT2G39920 5' sequence, length=1000 [CHR 2 START 16613083 ...   137  0.56      1
#AT4G09350 5' sequence, length=1000 [CHR 4 START 4896633 E...   133  0.71      1

            if ( m%^([Aa][Tt]\d[Gg]\d+)% ||
                 m%^(>[Aa][Tt]\d[Gg]\d+)% )
            {
                s%^([Aa][Tt]\d[Gg]\d+) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%<A NAME="$1_H"></A><b><a href="$LOCUS_DETAIL$1" target=_new>$1</A></b> $2 <a href="#$1_A">$3</A> $4%o;
                s%^>([Aa][Tt]\d[Gg]\d+) %><A NAME="$1_A"></A><b><a href="$LOCUS_DETAIL$1" target=_new>$1</A></b> %o;
            }

            #
            # Matches At_transcript
            #
            
            #AT1G01010.1 
            #AT5G48130.1 
            #AT5G37740.1 

            #
            # Matches At_intron_20020107
            #
            
#AT1G01010-I2 length=209 [CHR 1 START 4277 END 4485]  FORWARD   640  4.3e-24   1
#AT5G48130-I1 length=98 [CHR 5 START 19230295 END 19230392...   142  0.25      1
#AT5G37740-I1 length=704 [CHR 5 START 14706169 END 1470687...   138  0.34      1

            if ( m%^([Aa][Tt]\d[Gg]\d+[\-\.]\S+)% ||
                 m%^(>[Aa][Tt]\d[Gg]\d+[\-\.]\S+)% )
            {
                s%^([Aa][Tt]\d[Gg]\d+)([\-\.]\S+) ( *.*) ( *\d[0-9e\-\.]{0,}) ( *\d*)$%<A NAME="$1$2_H"></A><b><a href="$LOCUS_DETAIL$1" target=_new>$1</A>$2</b> $3 <a href="#$1$2_A">$4</A> $5%o;
                s%^>([Aa][Tt]\d[Gg]\d+)([\-\.]\S+) %><A NAME="$1$2_A"></A><b><a href="$LOCUS_DETAIL$1" target=_new>$1</A>$2</b> %o;
            }

            if ( /^$/ ) 
            {
                print( "\n" ); 
            }
            else 
            {  
                print( "$_\n" );  
            }
      
            if ( m%^  Start: % )
            {
                $FoundTable = 0;
                #print( "<B>END OF ONE QUERY</B>\n" );
            }
        }
    } #End of While
  
    close( BLAST_RESULT );
  
    print( "</PRE>" );
    print( "</font>\n" );
    print( "</td></tr></table>\n " );

} #End of convert function

return 1;
