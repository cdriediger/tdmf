class Auth_dummy

  def init_module
  end

  def valid_credentials?(username, passwd)
    puts "Checking credentials: User: #{username}  Passwd: #{passwd}"
    return true
  end

end
