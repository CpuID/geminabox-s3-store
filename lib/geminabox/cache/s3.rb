module Geminabox
  module Cache
    class S3
      attr_reader :logger

      def initialize (bucket: nil, logger: Logger.new(STDOUT))
        @bucket = bucket
        @logger = logger
      end

      def s3_object (file_name)
        "spec_cache/#{file_name}"
      end

      def pre_read(file_name)
        file_basename = File.basename(file_name)
        s3_key = s3_object(file_basename)
        if @bucket.objects[s3_key].exists?
          if File.exist? file_name and @bucket.objects[s3_key].last_modified > File.mtime file_name
            File.open(file_name, 'wb') do |file|
              @bucket.objects[s3_key].read do |chunk|
                file.write(chunk)
              end
            end
            logger.info "#{s3_key} found on S3, written out to #{file_name}"
          else
            logger.info "#{s3_key} found on S3, but identical modification time to local, not downloading."
          end
        else
          logger.info "#{s3_key} does not exist on S3, not retrieving."
        end
      end

      def post_write(file_name)
        file_basename = File.basename(file_name)
        s3_key = s3_object(file_basename)
        @bucket.objects[s3_key].write IO.read(file_name)
        logger.info "#{file_name} written out to S3 key #{s3_key}"
      end
    end
  end
end
