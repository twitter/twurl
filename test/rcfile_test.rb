require File.dirname(__FILE__) + '/test_helper'
# File.unlink(RCFile.file_path)
class Twurl::RCFile::PathConstructionTest < Test::Unit::TestCase
  def test_file_path_appends_file_to_directory
    assert_equal File.join(Twurl::RCFile.directory, Twurl::RCFile::FILE), Twurl::RCFile.file_path
  end
end

class Twurl::RCFile::LoadingTest < Test::Unit::TestCase
  def test_load_parses_and_loads_file_if_it_exists
    mock(YAML).load_file(Twurl::RCFile.file_path).times(1)
    mock(Twurl::RCFile).default_rcfile_structure.never

    Twurl::RCFile.load
  end

  def test_load_returns_default_file_structure_if_file_does_not_exist
    mock(YAML).load_file(Twurl::RCFile.file_path) { raise Errno::ENOENT }.times(1)
    mock(Twurl::RCFile).default_rcfile_structure.times(1)

    Twurl::RCFile.load
  end
end

class Twurl::RCFile::InitializationTest < Test::Unit::TestCase
  def test_initializing_when_the_file_does_not_exist_loads_default_rcfile_structure
    mock(YAML).load_file(Twurl::RCFile.file_path) { raise Errno::ENOENT }.times(1)

    rcfile = Twurl::RCFile.new
    assert_equal Twurl::RCFile.default_rcfile_structure, rcfile.data
  end

  def test_initializing_when_the_file_does_exists_loads_content_of_file
    mock_content_of_rcfile = {'this data' => 'does not matter'}
    mock(YAML).load_file(Twurl::RCFile.file_path) { mock_content_of_rcfile }.times(1)
    mock(Twurl::RCFile).default_rcfile_structure.never

    rcfile = Twurl::RCFile.new
    assert_equal mock_content_of_rcfile, rcfile.data
  end
end

class Twurl::RCFile::DefaultProfileFromDefaultRCFileTest < Test::Unit::TestCase
  attr_reader :rcfile
  def setup
    mock(YAML).load_file(Twurl::RCFile.file_path) { raise Errno::ENOENT }.times(1)
    mock.proxy(Twurl::RCFile).default_rcfile_structure.times(1)

    @rcfile = Twurl::RCFile.new
  end

  def test_default_rcfile_structure_has_no_default_profile
    assert_nil rcfile.default_profile
  end

  def test_setting_default_profile
    username = 'noradio'
    options  = Twurl::CLI::Options.new
    options.username = username

    client = Twurl::OAuthClient.load_new_client_from_options(options)
    rcfile.default_profile = client
    assert_equal username, rcfile.default_profile
  end
end

class Twurl::RCFile::ConfigurationTest < Test::Unit::TestCase
end