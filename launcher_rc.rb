# This file is loaded when the launcher is initialized.

BUFFER_SIZE_BYTES = 2 * 1024 * 1024

def increase_jetty_buffer_size(server, *)
  server.getConnectors.each do |connector|
    $stderr.puts("Increasing buffer size for #{connector} to #{BUFFER_SIZE_BYTES}")
    connector.setRequestHeaderSize(BUFFER_SIZE_BYTES)
  end
end


add_server_prepare_hook(proc {|*args| increase_jetty_buffer_size(*args)})
