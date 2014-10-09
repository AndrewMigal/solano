# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class Ssh
    class << self
      include TddiumConstant

      def load_ssh_key(ssh_file, name)
        begin
          data = File.open(File.expand_path(ssh_file)) {|file| file.read}
        rescue Errno::ENOENT => e
          raise TddiumError.new(Text::Error::INACCESSIBLE_SSH_PUBLIC_KEY % [ssh_file, e])
        end

        if data =~ /^-+BEGIN \S+ PRIVATE KEY-+/ then
          raise TddiumError.new(Text::Error::INVALID_SSH_PUBLIC_KEY % ssh_file)
        end
        if data !~ /^\s*ssh-(dss|rsa)/ && data !~ /^\s*ecdsa-/ then
          raise TddiumError.new(Text::Error::INVALID_SSH_PUBLIC_KEY % ssh_file)
        end

        {:name=>name,
         :pub=>data, 
         :hostname=>`hostname`, 
         :fingerprint=>`ssh-keygen -lf #{ssh_file}`}
      end

      def generate_keypair(name, output_dir)
        filename = File.expand_path(File.join(output_dir, "identity.tddium.#{name}"))
        pub_filename = filename + ".pub"
        if File.exists?(filename) then
          raise TddiumError.new(Text::Error::KEY_ALREADY_EXISTS % filename)
        end
        cmd = "ssh-keygen -q -t rsa -P '' -C 'tddium.#{name}' -f #{filename}"
        exit_failure Text::Error::KEYGEN_FAILED % name unless system(cmd)
        {:name=>name,
         :pub=>File.read(pub_filename), 
         :hostname=>`hostname`, 
         :fingerprint=>`ssh-keygen -lf #{pub_filename}`}
      end

      def validate_keys name, path, tddium_api, generate_new_key = false
        keys_details, keydata = tddium_api.get_keys, nil

        # key name should be unique
        if keys_details.count{|x|x['name'] == name} > 0
          abort Text::Error::ADD_KEYS_DUPLICATE % name
        end

        unless generate_new_key
          # check out key's content uniqueness
          keydata = self.load_ssh_key(path, name)
          duplicate_keys = keys_details.select{|key| key['pub'] == keydata[:pub] }
          unless duplicate_keys.empty?
            abort Text::Error::ADD_KEY_CONTENT_DUPLICATE % duplicate_keys.first['name']
          end
        else
          # generate new key
          keydata = self.generate_keypair(name, path)
        end

        keydata
      end
    end
  end
end
