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
        docker["containers"].each do |container|
          unless output.include? container
            msg << "r_docker_container_status{name=#{container},status_name='NOT_FOUND',exit_code=666} 0
r_docker_container_uptime{name=#{container}} 0
r_docker_container_downtime{name=#{container}} 0
"
            next
          end

          docker_inspect = YAML.load(%x(docker inspect #{container}))
          state          = docker_inspect.first["State"]

          status   = (state['Status'].downcase == 'running')? 10 : -1
          uptime   = (status == 10)? (Time.now - DateTime.parse(state['StartedAt']).to_time).to_i : 0
          downtime = (status == 10)? 0 : (Time.now - DateTime.parse(state['FinishedAt']).to_time).to_i

          msg <<
            "r_docker_container_status{name=#{container},status_name=#{state['Status']},exit_code=#{state['ExitCode']}} #{status}
r_docker_container_uptime{name=#{container}} #{uptime}
r_docker_container_downtime{name=#{container}} #{downtime}
"
        end

        msg.string
      end
    end
  end
end
