# =begin pod
# =head1 Clu::Ingester
# =para
# Ingests a TOML file with information about a command.
#
# =end pod

unit module Clu::Ingester:ver<1.0.0>:auth<masukomi (masukomi@masukomi.org)>;
use Definitely;
# use Terminal::ANSIColor;
# use Text::MiscUtils::Layout;
use Clu::TerminalUtilities;
# use Color;
use DB::SQLite;
use TOML;

our sub ingest-metadata(Str $path, DB::SQLite $db) returns Bool is export {
	#TODO: convert relative paths to absolute
	# convert ~ to $*HOME
	my $cleaned_path = $path.subst(/^^ "~"/, $*HOME);

	die("$cleaned_path doesn't end with .toml")                 unless $cleaned_path.ends-with('.toml');
	# test if the file exists at that cleaned_path
	die("$cleaned_path doesn't exist")                          unless $cleaned_path.IO.e;
	# read the file
	# parse the toml
	my %metadata = from-toml($cleaned_path.IO.slurp);
	# ^ that doesn't fail if it's not TOML
	# BUT %config.^name would be "Any" in that case, so...
	die("$path didn't appear to contain valid TOML")	unless %metadata.^name eq "Hash";
	die("$path didn't have a 'name' key")				unless %metadata<name>.Bool;
	die("$path didn't have a 'description' key")		unless %metadata<description>.Bool;
	# see if anything exists in the db for that command
	given find-command-id(%metadata<name>, $db) {
		# if yes, update
		when $_ ~~ Some {
			update-command($_.value, %metadata, $db);
		}
		# if no, insert
		default {
			insert-command(%metadata, $db);
		}
	}
	return True;
}

our sub find-command-id($command_name, DB::SQLite $db) returns Maybe[Int] {
	my $val = $db.query('SELECT id FROM commands WHERE name=$name', name => $command_name).value;
	$val ~~ Int ?? something($val) !! nothing(Int);
}
our sub insert-command(%command, $db){
	my $insert_sql = q:to/END/;
INSERT INTO commands (
	name,
	description,
	usage_command,
	fallback_usage,
	type,
	language,
	source_url,
	source_repo_url
) VALUES (
	?,
	?,
	?,
	?,
	?,
	?,
	?,
	?
);
END
   my $statement_handle = $db.db.prepare($insert_sql);
   $statement_handle.execute(executable-list(%command));

}

our sub update-command($id, %command, $db){
	# there's a bug in DB::SQLite
	# https://github.com/CurtTilmes/raku-dbsqlite/issues/18
	# you can't used named parms with
	# .execute unless you bind them each individually
	my $update_sql = q:to/END/;
UPDATE commands SET
  name              = ?,
  description       = ?,
  usage_command     = ?,
  fallback_usage    = ?,
  type              = ?,
  language          = ?,
  source_url        = ?,
  source_repo_url   = ?

WHERE id = ?;
END

   my $statement_handle = $db.db.prepare($update_sql);
   my @list_with_id = executable-list(%command);
   @list_with_id.append($id);
   $statement_handle.execute(@list_with_id)
}

our sub executable-list(%command) {
	   [
		   %command<name>, # guaranteed present
			%command<description>,
			(%command<usage_command> or Nil),
			( %command<fallback_usage> or Nil ),
			( %command<type> or Nil ),
			( %command<language> or Nil ),
			( %command<source_url> or Nil ),
			( %command<source_repo_url> or Nil )
	   ]
}
# commenting out until the DB::SQLite bug is fixed
# https://github.com/CurtTilmes/raku-dbsqlite/issues/18
# our sub executable-hash(%command) {
# 	   name				=> %command<name>, # guaranteed present
# 	   description		=> %command<description>,
# 	   usage_command	=> ( %command<usage_command> or Nil ),
# 	   fallback_usage	=> ( %command<fallback_usage> or Nil ),
# 	   type				=> ( %command<type> or Nil ),
# 	   language			=> ( %command<language> or Nil ),
# 	   source_url		=> ( %command<source_url> or Nil ),
# 	   sourc_repo_url	=> ( %command<source_repo_url> or Nil )
# }
