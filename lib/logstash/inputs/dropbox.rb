# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require_relative "./dropbox-patch"

require "time"
require "tmpdir"
require "stud/interval"
require "stud/temporary"

require "dropbox_sdk"

# Stream events from files from a Dropbox folder.
#
# Each line from each file generates an event.
class LogStash::Inputs::Dropbox < LogStash::Inputs::Base

  config_name "dropbox"

  default :codec, "plain"

  # your dropbox app credentials
  # Credentials can be specified:
  # - As an ["key","secret"] array
  config :credentials, :validate => :array

  # The token of the folder you need to access
  config :token, :validate => :string, :required => true

  # If specified, the prefix of filenames in the bucket must match
  config :prefix, :validate => :string, :default => "/"

  # # Name of a Dropbox folder path to backup processed files to.
  config :backup_to_folder, :validate => :string, :required => true

  config :backup_to_prefix_file, :validate => :string, :required => true

  # Interval to wait between to check the file list again after a run is finished.
  # Value is in seconds.
  config :interval, :validate => :number, :default => 60

  public
  def register
    @dropboxbucket = get_dropboxobject
  end # def register

  public
  def run(queue)
    Stud.interval(@interval) do
      process_files(queue)
    end
  end # def run

  public
  def list_new_files
    objects = {}
    folder, _ = @dropboxbucket.metadata(@prefix)
    return folder["contents"]
  end # def fetch_new_files

  public
  def process_files(queue)
    objects = list_new_files

    objects.each do |key|
      process_log(queue, key) if !key["is_dir"]
    end
  end # def process_files

  private
  def process_local_log(queue, dropboxfile)

    metadata = {}

    content, _ = @dropboxbucket.get_file_and_metadata(dropboxfile["path"])

    content.split("\n").each do |line|
      @codec.decode(line) do |event|
        decorate(event)
        queue << event
        # end
      end
    end
  end # def process_local_log

  public
  def process_log(queue, key)
    object = key
    process_local_log(queue, object)
    move_to_backup_folder(object)
  end

  private
  def move_to_backup_folder(object)
    backup_file_path =  "#{@backup_to_folder}#{Time.now.strftime("%d%m%Y-%H%M%S")}-#{@backup_to_prefix_file}.#{File.basename(object["path"])}"
    @dropboxbucket.file_move("#{object["path"]}", backup_file_path)
  end

  private
  def get_dropboxobject

    # TODO: (ph) Deprecated, it will be removed
    if @credentials.length == 2
      @access_key_id = @credentials[0]
      @secret_access_key = @credentials[1]
    else
      @logger.error("Credentials missing, at least one of them.")
    end

    if @credentials && @token
      DropboxClient.new(@token)
    end
  end

end # class LogStash::Inputs::Dropbox
