#!/usr/bin/ruby

require 'rubygems'
require 'yaml'
require 'aws-sdk-v1'

class ShowEC2Instance
  def initialize
    @config = YAML.load_file("config/sample_ec2.yml")
    @ec2 = AWS::EC2::new(
      access_key_id: @config["access_key_id"],
      secret_access_key: @config["secret_access_key"],
      region: @config["region"]
     )
  end
#--------------- Check Arguments ---------------
  def argvcheck
      if ARGV[0] == "check" && ARGV[1] == nil
        self.checkall
      elsif ARGV[0] == "check" && ARGV[1] == "run"
        self.check("run")
      elsif ARGV[0] == "check" && ARGV[1] == "stop"
        self.check("stop")
      elsif ARGV[0] == nil
        puts "Usage: ruby get_ec2_instance.rb [argv1] [argv2]"
        puts ' argv1 : check'
        puts ' argv2 : run,stop'
        exit
      else
        puts 'Illegalle Input.'
      end
  end

#---------- Check All EC2 Instances ---------
  def checkall
      begin
          puts '#instance-id |  status |  ipaddress |'
          @ec2.instances.each do |ins|
            puts "#{ins.id}\t#{ins.status}\t  #{ins.ip_address}"
          end
      rescue AWS::EC2::Errors::AuthFailure => e
          puts e.message
          puts '[ERROR] Get EC2 Instance Status Failed.'
          exit
      rescue NoMethodError => e
          puts e.message
          puts '[ERROR] NoMethodError.'
          exit
      rescue SocketError => e
        puts e.message
        puts '[ERROR] SocketError,'
        exit
      end
  end

#---------- Check Running or Stopping EC2 Instances ---------
  def check(opr)
      if opr == "run"
        status = 'running'
      elsif opr == "stop"
        status = 'stopped'
      end

      i = @ec2.client.describe_instances(:filters => [{ 'name' => 'instance-state-name', 'values' => [status] }])
      num = @ec2.instances.count
      begin
        initialize_value = 0
          puts '---------------'
        while initialize_value < num do
          run_insid = i.reservation_set[initialize_value][:instances_set][0][:instance_id]
          print 'ID:'
          puts run_insid
          initialize_value += 1
          end
        rescue NoMethodError => e
          puts '---------------'
        rescue SocketError => e
          puts e.message
          puts '[ERROR] SocketError.'
          exit
      end
  end
end

obj = ShowEC2Instance.new
obj.argvcheck
