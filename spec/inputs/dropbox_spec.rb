# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/dropbox"
require "logstash/errors"
require "dropbox_sdk"
require "stud/temporary"
require_relative "../support/helpers"

describe LogStash::Inputs::Dropbox do
  before do
    # DropboxClient.stub!
    Thread.abort_on_exception = true
  end
  let(:day) { 3600 * 24 }
  let(:settings) {
    {
      # "access_key_id" => "1234",
      # "secret_access_key" => "secret",
      "credentials" => [ "90xpj25b6k0qv3e","rrfb8l6f824olm7"],
      "token" => "36urfzNJ8pAAAAAAAAAABRnDjV981R7vPk7ZYf0cbMZDvxTJiZ5PM2Ex7P-PwPTx"

    }
  }

  describe "#list_new_files" do

    # let!(:present_object) { double(:key => 'this-should-be-present', :last_modified => Time.now) }
    # let(:objects_list) {
    #   [
    #     double(:key => 'exclude-this-file-1', :last_modified => Time.now - 2 * day),
    #     double(:key => 'exclude/logstash', :last_modified => Time.now - 2 * day),
    #     present_object
    #   ]
    # }

    # it 'should support not providing a exclude pattern' do
    #   config = LogStash::Inputs::Dropbox.new(settings)
    #   config.register
    #   expect(config.list_new_files).to eq(objects_list.map(&:key))
    # end

    it 'should support doing local backup of files' do

        config = LogStash::Inputs::Dropbox.new(settings)
        config.register
        # expect(config.process_files)

        objects = config.list_new_files
        objects.each do |key|

          debugger
          config.process_log(nil, key) if !key["is_dir"]c
        end

    end

    # it 'should accepts a list of credentials for the aws-sdk, this is deprecated' do
    #   Stud::Temporary.directory do |tmp_directory|
    #     old_credentials_settings = {
    #       "credentials" => ['1234', 'secret'],
    #       "backup_to_dir" => tmp_directory,
    #       "bucket" => "logstash-test"
    #     }

    #     config = LogStash::Inputs::Dropbox.new(old_credentials_settings)
    #     expect{ config.register }.not_to raise_error
    #   end
    # end
  end

  # context 'when working with logs' do
  #   let(:objects) { [log] }
  #   let(:log) { double(:key => 'uncompressed.log', :last_modified => Time.now - 2 * day) }

  #   before do
  #     allow_any_instance_of(AWS::S3::ObjectCollection).to receive(:with_prefix).with(nil) { objects }
  #     allow_any_instance_of(AWS::S3::ObjectCollection).to receive(:[]).with(log.key) { log }
  #     expect(log).to receive(:read)  { |&block| block.call(File.read(log_file)) }
  #   end

  #   context 'compressed' do
  #     let(:log) { double(:key => 'log.gz', :last_modified => Time.now - 2 * day) }
  #     let(:log_file) { File.join(File.dirname(__FILE__), '..', 'fixtures', 'compressed.log.gz') }

  #     it 'should process events' do
  #       events = fetch_events(settings)
  #       expect(events.size).to eq(2)
  #     end
  #   end

  #   context 'plain text' do
  #     let(:log_file) { File.join(File.dirname(__FILE__), '..', 'fixtures', 'uncompressed.log') }

  #     it 'should process events' do
  #       events = fetch_events(settings)
  #       expect(events.size).to eq(2)
  #     end
  #   end

  #   context 'encoded' do
  #     let(:log_file) { File.join(File.dirname(__FILE__), '..', 'fixtures', 'invalid_utf8.log') }

  #     it 'should work with invalid utf-8 log event' do
  #       events = fetch_events(settings)
  #       expect(events.size).to eq(2)
  #     end
  #   end

  #   context 'cloudfront' do
  #     let(:log_file) { File.join(File.dirname(__FILE__), '..', 'fixtures', 'cloudfront.log') }

  #     it 'should extract metadata from cloudfront log' do
  #       events = fetch_events(settings)

  #       expect(events.size).to eq(2)

  #       events.each do |event|
  #         expect(event['cloudfront_fields']).to eq('date time x-edge-location c-ip x-event sc-bytes x-cf-status x-cf-client-id cs-uri-stem cs-uri-query c-referrer x-page-url​  c-user-agent x-sname x-sname-query x-file-ext x-sid')
  #         expect(event['cloudfront_version']).to eq('1.0')
  #       end
  #     end
  #   end
  # end
end
