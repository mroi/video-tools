#!/usr/bin/perl

use strict;
use warnings;
use XML::LibXML;

if ($#ARGV != 0) {
	print "Usage: $0 <FCPXML file>\n";
	exit;
}

my $xml = XML::LibXML->new->parse_file($ARGV[0]);
for my $project ($xml->findnodes('//project')) {
	for my $node ($project->findnodes('//keyword')) {
		print STDERR "keyword ‘" . $node->getAttribute('value') . "’ in ‘" . $project->getAttribute('name') . "’\n";
		$node->parentNode->removeChild($node);
	}
}
print $xml->toString;
