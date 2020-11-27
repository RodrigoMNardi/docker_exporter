require 'date'
require 'stringio'
require 'yaml'

module Exporter
  module Docker
    class << self
      def export
        msg  = StringIO.new

        return msg.string unless File.exist? "#{File.dirname(__FILE__)}/../docker.yml"

        docker = YAML::load(IO.read("#{File.dirname(__FILE__)}/../docker.yml"))
        return msg.string if docker.nil? or docker.empty?

        output = %x(docker ps -a --format '{{.Names}}').split("\n")
        output.each do |entry|
          next unless docker["containers"].include? entry

          docker_inspect = YAML.load(%x(docker inspect #{entry}))
          state          = docker_inspect.first["State"]

          status   = (state['Status'].downcase == 'running')? 10 : -1
          uptime   = (status == 10)? (Time.now - DateTime.parse(state['StartedAt']).to_time).to_i : 0
          downtime = (status == 10)? 0 : (Time.now - DateTime.parse(state['FinishedAt']).to_time).to_i

          msg << "container_status{name=#{entry},status_name=#{state['Status']},exit_code=#{state['ExitCode']}} #{status}
container_uptime{name=#{entry}} #{uptime}
container_downtime{name=#{entry}} #{downtime}
"
        end

        msg.string
      end
    end
  end
end
