# def fetch_events(settings)
#   queue = []
#   dropbox = LogStash::Inputs::S3.new(settings)
#   dropbox.register
#   dropbox.process_files(queue)
#   dropbox.teardown
#   queue
# end


# def list_remote_files(prefix, target_bucket = ENV['AWS_LOGSTASH_TEST_BUCKET'])
#   bucket = dropboxobject.buckets[target_bucket]
#   bucket.objects.with_prefix(prefix).collect(&:key)
# end


# def dropboxobject
#   DropboxClient.new
# end
