#!/usr/bin/ruby
####
require 'rubygems'
require 'yaml'
require 'aws-sdk-v1'

class StartEC2Instance
  def initialize
    config = YAML.load_file("config/sample_ec2.yml")
    @ec2 = AWS::EC2::new(
      access_key_id: config["access_key_id"],
      secret_access_key: config["secret_access_key"],
      region: config["region"]
    )
  end

# +++++ Check Arguments +++++
  def argvcheck
      if ARGV.count < 4
        if ARGV[0] == "select" && ARGV[1] == nil && ARGV[2] == nil && ARGV[3] == nil
          self.extraction_stop_instance
          self.create_start_list
          self.list_start_instance
          self.start_instance
          exit
        elsif ARGV[0] == "silent" && ARGV[1] == "all" && ARGV[2] == nil && ARGV[3] == nil
          self.extraction_stop_instance
          @@ary_stoplist_tobe = @@ary_stop_detail
          self.start_instance
          exit
        elsif ARGV[0] == "silent" && ARGV[1] == "insid" && ARGV[2].kind_of?(String) == true && ARGV[3] == nil
          self.extraction_stop_instance
          puts 'aaaaaa'
          if @@ary_stop_detail.include?(ARGV[2]) == true
            self.start_instance_simple(ARGV[2].to_s)
          end
          exit
        elsif ARGV[0] == nil
          puts "Usage: ruby start_ec2_instance.rb [argv1] [argv2]"
          puts ' argv1: select or silent'
          puts ' argv2: (if argv1 is silent) all or insid'
          exit
        else 
        puts "[ERROR] Arguments Failed2"
        end
      else
        puts '[ERROR] Too much Arguments.'
      end
  end

# +++++ Create Instance ID Array List ++++++
  def extraction_stop_instance
    @@ary_stop_detail = []
    num = @ec2.instances.count
    initialize_value = 0
    i = @ec2.client.describe_instances(:filters => [{ 'name' => 'instance-state-name', 'values' => ['stopped'] }])
    begin
      while initialize_value < num do
        @@stop_insid = i.reservation_set[initialize_value][:instances_set][0][:instance_id]
        @@ary_stop_detail.push(@@stop_insid)
        initialize_value += 1
        end
      rescue SocketError => e
        puts '[ERROR] SocketError'
        puts e.message
        exit
      rescue NoMethodError => e
    end
  end

# +++++ Create Start Instance List +++++
  def create_start_list
    puts '--Stopping Instances-----'
    puts @@ary_stop_detail
    puts '-------------------------'
    puts 'Please Input Instance ID'
    puts '  1. To Stop instance      => i-xxxxxxx)'
    puts '  2. To End This Operation => end)'
    print 'Input ID to start Instance: '
    input_id = STDIN.gets.to_s.chomp
    @@ary_stoplist_tobe = []

    while input_id != "end" do
      if @@ary_stop_detail.include?(input_id) && @@ary_stoplist_tobe.include?(input_id) == false
         @@ary_stoplist_tobe.push(input_id)
         puts '--Assigned Start Instances List--'
         @@ary_stoplist_tobe.each do |youso|
          puts youso
         end
         print 'Input ID to start Instance: '
         input_id = STDIN.gets.to_s.chomp
      elsif input_id != @@stop_insid
         puts "Input ID Error."
         print 'Input ID to start Instance: '
         input_id = STDIN.gets.to_s.chomp
      end
    end
  end

# +++++ Method Name [list_stop_instance] +++++
  def list_start_instance
    if @@ary_stoplist_tobe.count == 0
      puts 'Nothing.'
      exit
    end

    puts ''
    puts '******************'
    puts @@ary_stoplist_tobe
    puts '******************'
    puts ''
    puts 'Those Instances will be Stop.'
    print 'OK? (yes or no) :'
    enter_start = STDIN.gets.chomp
    if enter_start != "yes"
      puts 'Operation End.'
      exit
    end
  end

# +++++ Method Name [start_instance] +++++
  def start_instance
    @@ary_stoplist_tobe.each do |youso|
      print "Starting: ", youso
      puts ''
      @ec2.client.start_instances({
        instance_ids: [youso],
        #additional_info: "String",
        dry_run: false,
      })
    end
  end

# ++++++ Method name [start_instance_simple]
  def start_instance_simple(string)
    print "Starting: ", string
    @ec2.client.start_instances({
      instance_ids: [string],
      dry_run: false,
      })
  end
end  

obj = StartEC2Instance.new
obj.argvcheck
