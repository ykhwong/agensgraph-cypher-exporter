use strict;
use IPC::Open2;
my ($pid, $out, $in);
my %node;
my $flag;
my $row_show_cnt=0;
my $changed=0;
my $compt="agens";
my $idx_uniq_st;
my $no_index=0;

sub _get_idx {
	my $ls = shift;
	if ($ls !~ /^.+\s*\|\s*(CREATE +PROPERTY +INDEX )/i) {
		return;
	}
	$ls =~ s/^.+\s*\|\s*(CREATE +PROPERTY +INDEX )/$1/i;
	$ls =~ s/\)(\s*)$/);$1/;
	if ($compt eq "agens") {
		$idx_uniq_st .= $ls;
		return;
	}
	$ls =~ s/CREATE +PROPERTY +INDEX +(.+) +ON +(\S+) +USING +btree *\((.+)\)/CREATE INDEX ON :$2($3)/i;
	$idx_uniq_st .= $ls;
}

sub proc {
	my $ls = shift;
	if ($compt eq "agens") {
		$ls =~ s/'/''/g;
		$ls =~ s/\\"([\},])/\\\\'$1/g;
		$ls =~ s/([^\\])(`|")/$1'/g;
		$ls =~ s/\\"/"/g;
	}
	return "" if ($ls =~ /^-+\s*$/);
	if ($ls =~ /^\((\d+) rows*\)/) {
		$row_show_cnt++;
		return "";
	}
	if ($ls =~ /^\s*(n|r)\s*$/) {
		$flag=$1;
		return "";
	}
	if ($flag eq "n") {
		if ($ls =~ /^ +(\S+)\[(\d+\.\d+)\]\{(.*)\}\s*$/) {
			my $vlabel = $1;
			my $s_id = $2;
			my $prop = $3;
			$node{$s_id} = $vlabel . "\t" . $prop;
			$changed=1;
			return "CREATE (:$vlabel {$prop});\n";
		}
	}
	if ($flag eq "r") {
		if ($ls =~ /^ +(\S+)\[(\d+\.\d+)\]\[(\d+\.\d+),(\d+\.\d+)\]\{(.*)\}\s*$/) {
			my $elabel = $1;
			my $n1_id = $3;
			my $n2_id = $4;
			my ($n1_vlabel, $n1_prop) = (split /\t/, $node{$n1_id});
			my ($n2_vlabel, $n2_prop) = (split /\t/, $node{$n2_id});
			$changed=1;
			return "MATCH (n1:$n1_vlabel {$n1_prop}), (n2:$n2_vlabel {$n2_prop}) CREATE (n1)-[:$elabel]->(n2);\n";
		}
	}
	return "";
}

sub make_graph_st {
	my $graph_name = shift;
	return "DROP GRAPH IF EXISTS $graph_name CASCADE;\nCREATE GRAPH $graph_name;\nSET GRAPH_PATH=$graph_name;";
}

sub main {
	my $graph_name;
	my ($st, $graph_st);
	my $opt;
	foreach my $arg (@ARGV) {
		if ($arg =~ /^--graph=(\S+)$/) {
			$graph_name=$1;
			next;
		}
		if ($arg =~ /^--compt=(\S+)$/) {
			$compt=$1;
			next;
		}
		if ($arg =~ /^--no-index$/) {
			$no_index=1;
			next;
		}
		if ($arg =~ /^(--)(dbname|host|port|username)(=\S+)$/) {
			$opt.=" " . $1 . $2 . $3;
			next;
		}
		if ($arg =~ /^(--)(no-password|password)$/) {
			$opt.=" " . $1 . $2;
			next;
		}
		if ($arg =~ /^--/ || $arg =~ /^--(h|help)$/) {
			printf("USAGE: perl $0 [--graph=GRAPH_NAME] [--compt={agens|neo4j}] [--no-index] [--help]\n");
			printf("   Basic parameters:\n");
			printf("      [--compt=agens]   : Output for AgensGraph (default)\n");
			printf("      [--compt=neo4j]   : Output for Neo4j\n");
			printf("   Additional optional parameters for the AgensGraph integration:\n");
			printf("      [--dbname=DBNAME] : Database name\n");
			printf("      [--host=HOST]     : Hostname or IP\n");
			printf("      [--port=PORT]     : Port\n");
			printf("      [--username=USER] : Username\n");
			printf("      [--no-password]   : No password\n");
			printf("      [--password]      : Ask password (should happen automatically)\n");
			exit 0;
		}
	}

	if ($compt !~ /^(agens|neo4j)$/) {
		printf("Invalid parameter: --compt=$compt\n");
		exit 1;
	}
	if (!$graph_name) {
		printf("Please specify the --graph= parameter for the graph repository.\n");
		exit 1;
	}

	if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'dos') {
		`agens --help >nul 2>&1`;
	} else {
		`agens --help >/dev/null 2>&1`;
	}
	if ($? ne 0) {
		printf("agens client is not available.\n");
		exit 1;
	}
	if ($compt eq "agens") {
		$graph_st = make_graph_st($graph_name);
		printf("%s\n", $graph_st);
	}
	$pid = open2 $out, $in, "agens -q $opt";
	die "$0: open2: $!" unless defined $pid;

	$st = "SET GRAPH_PATH=$graph_name; \\dGi $graph_name.*;";
	print $in $st . "\n";
	while (<$out>) {
		my $ls = $_;
		last if ($ls =~ /No matching property|^\(\d+ +rows\)/i);
		_get_idx($ls);
	}

	$st = "SET GRAPH_PATH=$graph_name; MATCH (n) RETURN n; MATCH ()-[r]->() RETURN r;";
	print $in $st . "\n";
	while (<$out>) {
		last if ($row_show_cnt eq 2);
		print proc($_);
	}

	if ($changed eq 0) {
		if ($compt eq "agens") {
			printf("-- Nothing to do\n");
		} else {
			printf("// Nothing to do\n");
		}
	}

	unless ($no_index) {
		printf("%s", $idx_uniq_st);
	}
}

main();

