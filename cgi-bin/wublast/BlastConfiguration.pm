package BlastConfiguration;

use Exporter;
@ISA = qw( Exporter );
@EXPORT_OK =
    qw( $dstDir $dstURL );

#------------------------------
# the /hotdocs/images/orfmap is a soft link to /home/arabidopsis/tmp/wublast
# for the generated images, will be cleaned up by a cron job
#------------------------------
#$dstDir = "/home/arabidopsis/htdocs/images/orfmap/";
#$dstURL = "http://www.arabidopsis.org/images/orfmap/";
$dstDir = "$ENV{DOCUMENT_ROOT}/images/orfmap/";
$dstURL = "/images/orfmap/";
