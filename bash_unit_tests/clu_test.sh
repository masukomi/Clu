#!/usr/bin/env sh

source ./test_suite_management.sh

if [ ! -e clu ]; then
	cd ../
	if [ ! -e clu ]; then
		echo "Run me from within the bash_unit_tests directory"
		exit 1
	fi
fi




test_01_hyphen_v () {
  #assert_equals expected actual message
  clu_hyphen_v=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu -v 2>&1 | head -n2 | tail -n1)
  assert_equals "$clu_hyphen_v" "  clu -V|--version[=Any] [--verbose[=Any]]" \
	  "should provide usage for clu -v"

  assert_status_code 2 "raku -I lib clu -v > /dev/null 2>&1"
}

test_02_confirm_no_db(){
	assert "test ! -e $DB_LOCATION"
}

test_03_list_empty(){
	no_content_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu list)
	assert_equals "Your database is currently empty." "$no_content_output"
}

test_04_hyphen_hyphen_version () {
  clu_hyphen_v=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu --version 2>&1 | sed -e "s/ running.*//")
  assert_equals "clu - provided by  ," "$clu_hyphen_v"\
	  "should provide usage for clu --version"

  assert_status_code 2 `raku -I lib clu --version > /dev/null 2>&1`
}

test_05_add_new() {
	file_path=$TEST_DATA_DIR"/raku_test_no_demo.meta.toml"
	add_new_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu add $file_path | sed -e "s/ \/.*//")
	assert_equals "Successfully ingested" "$add_new_output"
}

test_06_confirm_db(){
	assert "test -e $DB_LOCATION"
}

test_07_confirm_data() {
	commands_count=$(sqlite3 $DB_LOCATION 'select count(*) from commands');
	tags_count=$(sqlite3 $DB_LOCATION 'select count(*) from tags');
	commands_tags_count=$(sqlite3 $DB_LOCATION 'select count(*) from commands_tags');
	assert_equals "1" "$commands_count"
	assert_equals "2" "$tags_count"
	assert_equals "2" "$commands_tags_count"

}

test_08_add_existing() {
	file_path=$TEST_DATA_DIR"/raku_test_no_demo.meta.toml"
	add_existing_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu add $file_path | sed -e "s/ \/.*//")
	assert_equals "Successfully ingested" "$add_existing_output"
}

test_09_update() {
	file_path=$TEST_DATA_DIR"/raku_test_no_demo.meta.toml"
	update_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu update $file_path | sed -e "s/ \/.*//")
	assert_equals "Successfully ingested" "$update_output"
}

test_10_demo_missing_asciicast(){
	asciicast_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu demo raku_test_no_demo 2>&1 \
		| head -n1			)
	assert_equals "No asciicast url was specified for raku_test_no_demo" "$asciicast_output"
}

test_11_empty_demos_listing(){
	demos_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu demos )
	assert_equals "You don't have any commands with asciicast demos." "$demos_output"
}
test_12_add_asciicast() {
	file_path=$TEST_DATA_DIR"/raku_test_no_demo.cast"
	add_cast_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu update $file_path | sed -e "s/ \/.*//")
	assert_equals "Successfully ingested" "$add_cast_output"
}

test_13_demo_asciicast(){
	asciicast_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu demo raku_test_no_demo \
		| grep "echo" \
		| sed -e 's/^.* "//' -e 's/".*$//'			)
	assert_equals "test data" "$asciicast_output"
}
test_14_populated_demos_listing(){
	demos_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu demos )
	assert_equals "raku_test_no_demo | raku_test_no_demo test description rtnddescription" "$demos_output"
}

#  searching
# let's add a second one
test_15_add_second_command(){
	file_path=$TEST_DATA_DIR"/something_else.meta.toml"
	add_new_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu add $file_path | sed -e "s/ \/.*//")
	assert_equals "Successfully ingested" "$add_new_output"
}

test_16_list_shows_all(){
	list_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu list | wc -l | sed -e 's/^ *//')
	assert_equals "2" "$list_output"
}

test_17_filtered_list_is_filtered(){
	list_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu list demos | wc -l | sed -e 's/^ *//')
	assert_equals "1" "$list_output"
}

test_18_find_in_desc() {
	find_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu find rtnddescription | wc -l | sed -e 's/^ *//')
	assert_equals "1" "$find_output"

	find_output=$(XDG_DATA_HOME=$XDG_DATA_HOME raku -I lib clu find description | wc -l | sed -e 's/^ *//')
	assert_equals "2" "$find_output"

}