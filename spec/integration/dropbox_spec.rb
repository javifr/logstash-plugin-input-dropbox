require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/dropbox"
require "dropbox_sdk"
require "fileutils"
require_relative "../support/helpers"

describe LogStash::Inputs::Dropbox, :integration => true, :dropbox => true do
  # before do
  #   Thread.abort_on_exception = true

  #   upload_file('../fixtures/uncompressed.log' , "#{prefix}uncompressed_1.log")
  # end

  # after do
  # end

  # let(:temporary_directory) { Stud::Temporary.directory }

  # let(:prefix)  { 'logstash-dropbox-input-prefix/' }

  # let(:minimal_settings)  {  { "access_key_id" => ENV['DROPBOX_ACCESS_KEY_ID'],
  #                              "secret_access_key" => ENV['DROPBOX_SECRET_ACCESS_KEY'],
  #                              "prefix" => prefix,
  #                              "token" => token } }

  # it "support prefix to scope the remote files" do
  #   events = fetch_events(minimal_settings)
  #   expect(events.size).to eq(4)
  # end

  # it "add a prefix to the file" do
  #   fetch_events(minimal_settings.merge({ "backup_to_bucket" => ENV["AWS_LOGSTASH_TEST_BUCKET"],
  #                                                  "backup_add_prefix" => backup_prefix }))
  #   expect(list_remote_files(backup_prefix).size).to eq(2)
  # end


end
