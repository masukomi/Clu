# =begin pod
# =head1 Clu::Ingester
# =para
# Ingests a TOML file with information about a command.
#
# =end pod

unit module Clu::Exporter;
use XDG::GuaranteedResources; # to load the md template
use Template::Mustache;
# use Terminal::ANSIColor;
# use Text::MiscUtils::Layout;
# use Clu::TerminalUtilities;
use Clu::Command;
use Clu::Resourcer; # for the templates
# use Clu::Tagger;
# use Color;
use DB::SQLite;
# use TOML;

our sub export-markdown(IO::Path $target_directory, DB::SQLite $sqlite) returns Bool is export {
	# re target_directory:
	# * ~ has already been expanded
	# * presence has already been validated

	# Prep the queries
	my $search_sql = q:to/END/;
		select * from commands order by name ASC
	END

	my $tags_search_sql = q:to/END/;
		select tag from commands_tags ct
		inner join tags t on ct.tag_id = t.id
		where command_id = ?;
	END

	# Collect the data
	my $connection = $sqlite.db;
	my @commands = $connection.query($search_sql).hashes;
	# becaues the SQL would be complicated, and brute force is
	# still going to be ridiculously fast, we're just going to
	# query for tags for each command individually.
	my $tags_statement_handle = $connection.prepare($tags_search_sql);
	my $raw_template = get-md-template();
	for @commands -> $command_hash {
		my $md = generate-markdown($command_hash, $raw_template);
		my $filename = $command_hash<name>.subst(/['-'+ | \W+]/, '_').lc ~ '.md';
		persist-file($target_directory, $filename, $md);
	}
}

my sub persist-file(IO::Path $target_directory, Str $filename, Str $content){
	# FINISHME
}

my sub generate-markdown(Associative $command_hash, Str $template) {
	Template::Mustache.render($template, $command_hash);
}
my sub get-md-template(){
	my $md_template_resource_path = 'config/clu/markdown_export_template.mustache';
	my $markdown_template_file = guarantee-resource($md_template_resource_path,
												   Clu::Resourcer);
	$markdown_template_file.IO.slurp(False);
}
