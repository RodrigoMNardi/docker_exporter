# BSD 2-Clause License
#
# Copyright (c) 2020, Rodrigo Mello Nardi
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'rack'

require_relative 'exporter/docker'

handler = Rack::Handler::WEBrick
Rack::Utils.key_space_limit = 128

class LibvirtExporter
  ALLOWED      = '/metrics'
  CONTENT_TYPE = {"Content-Type" => "text/plain"}
  NOT_FOUND    = [404, CONTENT_TYPE, "404 - Page not found" ]
  SUCCESS      = 200

  def call(env)
    request = Rack::Request.new(env)
    return NOT_FOUND unless request.get?
    return NOT_FOUND unless request.path == ALLOWED
    [SUCCESS, CONTENT_TYPE, [Exporter::Docker.export]]
  end
end

handler.run(LibvirtExporter.new, {Host: '127.0.0.1', Port: 9293})
