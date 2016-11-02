#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use XML::LibXML;

binmode(STDERR, ":utf8");
no warnings 'experimental::smartmatch';

if ($#ARGV != 0) {
	print "Usage: $0 <FCPXML file>\n";
	exit;
}

sub container {
	my $node = $_[0]->parentNode;
	if ($node->nodeName eq 'resources') {
		return 'resources';
	}
	if ($node->nodeName eq 'project') {
		return 'project ‘' . $node->getAttribute('name') . '’ in ' . container($node);
	}
	if ($node->nodeName eq 'event') {
		return 'event ‘' . $node->getAttribute('name') . '’';
	}
	return container($node);
}
sub timevalue {
	return 0 unless defined $_[0];
	my @pieces = split '/', ($_[0] =~ s/s$//r);
	$pieces[1] = 1 unless defined $pieces[1];
	return $pieces[0] / $pieces[1];
}
sub remove {
	$_[0]->parentNode->removeChild($_[0]->previousSibling()) if $_[0]->previousSibling()->nodeType == XML_TEXT_NODE;
	$_[0]->parentNode->removeChild($_[0]);
}

my $xml = XML::LibXML->new->parse_file($ARGV[0]);

# remove keywords unless they are part of a visible keyword collection
my %keywordCollection;
for my $node ($xml->findnodes('//keyword-collection')) {
	push @{$keywordCollection{container($node)}}, $node->getAttribute('name');
}
for my $node ($xml->findnodes('//keyword')) {
	my $container = container($node);
	my $keywords = $node->getAttribute('value');
	my $allKnown = 1;
	for my $keyword (split ', ', $keywords) {
		$allKnown = 0 unless ($keyword ~~ $keywordCollection{$container});
	}
	next if $allKnown;
	print STDERR 'keyword ‘' . $keywords . '’ in ' . $container . "\n";
	remove $node;
}

# remove markers unless they are visible in a project timeline
for my $node ($xml->findnodes('//marker')) {
	my $container = container($node);
	if ($container =~ /^project / and $node->parentNode->nodeName =~ /^(asset-clip|mc-clip|ref-clip|sync-clip|video|transition)$/) {
		my $marker = timevalue($node->getAttribute('start'));
		my $start = $node->parentNode->nodeName eq 'transition' ? 3600 : timevalue($node->parentNode->getAttribute('start'));
		my $stop = $start + timevalue($node->parentNode->getAttribute('duration'));
		next if ($marker >= $start and $marker < $stop);
	}
	print STDERR 'marker ‘' . $node->getAttribute('value') . '’ in ' . $container . "\n";
	remove $node;
}

print $xml->toString;
