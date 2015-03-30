# encoding: utf-8
require "logstash/inputs/base"
require "lib/logstash/inputs/dropbox-patch"
require "logstash/namespace"
# require "logstash/plugin_mixins/aws_config"

require "time"
require "tmpdir"
require "stud/interval"
require "stud/temporary"

require "dropbox_sdk"

# Stream events from files from a S3 bucket.
#
# Each line from each file generates an event.
# Files ending in `.gz` are handled as gzip'ed files.
class LogStash::Inputs::Dropbox < LogStash::Inputs::Base

  config_name "dropbox"

  default :codec, "plain"

  # your dropbox app credentials
  # Credentials can be specified:
  # - As an ["key","secret"] array
  config :credentials, :validate => :array

  # The token of the folder you need to access
  config :token, :validate => :string, :required => true


  # If specified, the prefix of filenames in the bucket must match (not a regexp)
  config :prefix, :validate => :string, :default => nil

  # Where to write the since database (keeps track of the date
  # the last handled file was added to S3). The default will write
  # sincedb files to some path matching "$HOME/.sincedb*"
  # Should be a path with filename not just a directory.
  config :sincedb_path, :validate => :string, :default => nil

  # # Name of a S3 bucket to backup processed files to.
  # config :backup_to_bucket, :validate => :string, :default => nil

  # # Append a prefix to the key (full path including file name in dropbox) after processing.
  # # If backing up to another (or the same) bucket, this effectively lets you
  # # choose a new 'folder' to place the files in
  # config :backup_add_prefix, :validate => :string, :default => nil

  # Path of a local directory to backup processed files to.
  # config :backup_to_dir, :validate => :string, :default => nil

  # Whether to delete processed files from the original bucket.
  config :delete, :validate => :boolean, :default => false

  # Interval to wait between to check the file list again after a run is finished.
  # Value is in seconds.
  config :interval, :validate => :number, :default => 60

  # Ruby style regexp of keys to exclude from the bucket
  config :exclude_pattern, :validate => :string, :default => nil

  # Set the directory where logstash will store the tmp files before processing them.
  # default to the current OS temporary directory in linux /tmp/logstash
  config :temporary_directory, :validate => :string, :default => File.join(Dir.tmpdir, "logstash")

  public
  def register
    # require "digest/md5"
    # require "aws-sdk"

    # @region = get_region

    @dropboxbucket = get_dropboxobject

    # @dropboxbucket = dropbox.buckets[@bucket]

    # unless @backup_to_bucket.nil?
    #   @backup_bucket = dropbox.buckets[@backup_to_bucket]
    #   unless @backup_bucket.exists?
    #     dropbox.buckets.create(@backup_to_bucket)
    #   end
    # end

    # unless @backup_to_dir.nil?
    #   Dir.mkdir(@backup_to_dir, 0700) unless File.exists?(@backup_to_dir)
    # end
  end # def register

  public
  def run(queue)
    Stud.interval(@interval) do
      process_files(queue)
      @logger.info("Big fun shit run")
    end
  end # def run


  public
  def list_new_files
    objects = {}

    folder, _ = @dropboxbucket.metadata("/")

    debugger

    # folder, _ = @dropboxbucket.metadata("/#{@prefix}/")
    # folder["contents"].keep_if { |file| valid?(file) }.map { |file_hash| file_hash["path"] }

    # Checking new files!

    # @s3bucket.objects.with_prefix(@prefix).each do |log|

    #     if sincedb.newer?(log.last_modified)
    #       objects[log.key] = log.last_modified
    #     end
    # end
    # return objects.keys.sort {|a,b| objects[a] <=> objects[b]}


    # folder["contents"].each do |log|
    #   puts log
    # end

    return folder["contents"]
    # return objects.keys.sort {|a,b| objects[a] <=> objects[b]}
  end # def fetch_new_files


  public
  def process_files(queue)
    objects = list_new_files

    debugger

    objects.each do |key|
      process_log(queue, key)
    end

    # objects.each do |key|
    #   @logger.debug("Dropbox input processing" )

    #   debugger

    #   lastmod = @dropboxbucket.objects[key].last_modified

    #   process_log(queue, key)

    #   sincedb.write(lastmod)
    # end
  end # def process_files


  private
  def process_local_log(queue, dropboxfile)

    metadata = {}
    # Currently codecs operates on bytes instead of stream.
    # So all IO stuff: decompression, reading need to be done in the actual
    # input and send as bytes to the codecs.

    debugger

    content, _ = @dropboxbucket.get_file_and_metadata(dropboxfile["path"])

    read_file(content) do |line|
      @codec.decode(line) do |event|
        # We are making an assumption concerning cloudfront
        # log format, the user will use the plain or the line codec
        # and the message key will represent the actual line content.
        # If the event is only metadata the event will be drop.
        # This was the behavior of the pre 1.5 plugin.
        #
        # The line need to go through the codecs to replace
        # unknown bytes in the log stream before doing a regexp match or
        # you will get a `Error: invalid byte sequence in UTF-8'
        # if event_is_metadata?(event)
        #   @logger.debug('Event is metadata, updating the current cloudfront metadata', :event => event)
        #   update_metadata(metadata, event)
        # else
          decorate(event)

          queue << event
        # end
      end
    end
  end # def process_local_log

=begin


  private
  def event_is_metadata?(event)
    line = event['message']
    version_metadata?(line) || fields_metadata?(line)
  end

  private
  def version_metadata?(line)
    line.start_with?('#Version: ')
  end

  private
  def fields_metadata?(line)
    line.start_with?('#Fields: ')
  end

  private
  def update_metadata(metadata, event)
    line = event['message'].strip

    if version_metadata?(line)
      metadata[:cloudfront_version] = line.split(/#Version: (.+)/).last
    end

    if fields_metadata?(line)
      metadata[:cloudfront_fields] = line.split(/#Fields: (.+)/).last
    end
  end

=end

  private
  def read_file(filename, &block)
    # if gzip?(filename)
    #   read_gzip_file(filename, block)
    # else
      read_plain_file(filename, block)
    # end
  end

  def read_plain_file(filename, block)
    File.open(filename, 'rb') do |file|
      file.each(&block)
    end
  end

=begin


  private
  def sincedb
    @sincedb ||= if @sincedb_path.nil?
                    @logger.info("Using default generated file for the sincedb", :filename => sincedb_file)
                    SinceDB::File.new(sincedb_file)
                  else
                    @logger.info("Using the provided sincedb_path",
                                 :sincedb_path => @sincedb_path)
                    SinceDB::File.new(@sincedb_path)
                  end
  end

  private
  def sincedb_file
    File.join(ENV["HOME"], ".sincedb_" + Digest::MD5.hexdigest("#{@bucket}+#{@prefix}"))
  end

=end

  public
  def process_log(queue, key)
    object = key
    # object = @dropboxbucket.objects[key]

    # filename = File.join(temporary_directory, File.basename(key))

    # download_remote_file(object, filename)

    process_local_log(queue, object)

    # backup_to_bucket(object, key)
    # backup_to_dir(filename)

    # delete_file_from_bucket(object)
  end

=begin
  private
  def download_remote_file(remote_object, local_filename)
    @logger.debug("S3 input: Download remove file", :remote_key => remote_object.key, :local_filename => local_filename)
    File.open(local_filename, 'wb') do |dropboxfile|
      remote_object.read do |chunk|
        dropboxfile.write(chunk)
      end
    end
  end

  private
  def delete_file_from_bucket(object)
    if @delete and @backup_to_bucket.nil?
      object.delete()
    end
  end
=end
  private
  def get_dropboxobject

    # TODO: (ph) Deprecated, it will be removed
    if @credentials.length == 2
      @access_key_id = @credentials[0]
      @secret_access_key = @credentials[1]
    else
      @logger.error("Credentials missing, at least one of them.")
    end

    puts @token

    if @credentials && @token
      DropboxClient.new(@token)
    end
  end

  # private

  # module SinceDB
  #   class File
  #     def initialize(file)
  #       @sincedb_path = file
  #     end

  #     def newer?(date)
  #       date > read
  #     end

  #     def read
  #       if ::File.exists?(@sincedb_path)
  #         since = Time.parse(::File.read(@sincedb_path).chomp.strip)
  #       else
  #         since = Time.new(0)
  #       end
  #       return since
  #     end

  #     def write(since = nil)
  #       since = Time.now() if since.nil?
  #       ::File.open(@sincedb_path, 'w') { |file| file.write(since.to_s) }
  #     end
  #   end
  # end

end # class LogStash::Inputs::S3
