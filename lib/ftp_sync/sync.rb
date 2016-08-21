require "net/ftp"

module FTPSync
  class Sync
    attr_reader :remote_root, :local_root, :threads, :stdout, :dry_run

    def initialize(host:, username:, password:, remote_root:, local_root:, stdout: $stdout, dry_run: false)
      @remote_root, @local_root, @stdout, @dry_run = remote_root, local_root, stdout, dry_run

      @client = Net::FTP.new(host)
      @client.login(username, password)
      @client.chdir(remote_root)
    end

    def run
      #$stderr.puts "RUNNING dry_run=#{dry_run?.inspect}"
      Dir.chdir(local_root) do
        process_dir(".")
      end
    ensure
      client.close
    end

    private

    attr_reader :client

    def dry_run?
      dry_run
    end

    def process_dir(relative_path)
      stdout.puts "Syncing #{client.pwd}/#{relative_path}"
      remote_paths = client.nlst(relative_path)
      local_paths = Dir.entries(relative_path).reject { |p| p == "." || p == ".." }

      #$stderr.puts "\tremote_paths=#{remote_paths}\n\tlocal_paths=#{local_paths}"

      remote_paths_to_delete = remote_paths - local_paths
      new_local_paths = local_paths - remote_paths
      existing_paths = local_paths - new_local_paths

      [remote_paths_to_delete, new_local_paths, existing_paths].each do |path_set|
        path_set.map! { |p| File.join(relative_path, p) }
      end

      #$stderr.puts "\tremote_paths_to_delete=#{remote_paths_to_delete}\n\tnew_local_paths=#{new_local_paths}\n\texisting_paths=#{existing_paths}"

      remote_paths_to_delete.each do |path|
        puts "Deleting #{path} on the server"
        client.delete(path) unless dry_run?
      end

      new_local_paths.each do |path|
        if File.directory?(path)
          mkdir_and_upload(path)
        else
          puts "Uploading #{path} to the server"
          client.putbinaryfile(path, path) unless dry_run?
        end
      end

      existing_paths.each do |path|
        remote_mtime = client.mtime(path, true)
        local_mtime = File.mtime(path)
        if local_mtime > remote_mtime
          #$stderr.puts "\t#{path}: remote_mtime=#{remote_mtime}, local_mtime=#{local_mtime}"
          if File.directory?(path)
            process_dir(path)
          else
            puts "Uploading #{path} to the server"
            client.putbinaryfile(path, path) unless dry_run?
          end
        end
      end
    rescue Errno::ENOENT
      puts "Deleting #{relative_path} on the server"
      client.rmdir(relative_path) unless dry_run?
    rescue Net::FTPPermError => ex
      if ex.message.start_with?("550 ")
        mkdir_and_upload(relative_path)
      else
        raise ex
      end
    end

    def mkdir_and_upload(relative_path)
      puts "Creating #{relative_path} on the server"
      client.mkdir(relative_path) unless dry_run?
    rescue Net::FTPReplyError => ex
      if ex.message.start_with?("250 ")
        process_dir(relative_path)
      else
        raise ex
      end
    end
  end
end
