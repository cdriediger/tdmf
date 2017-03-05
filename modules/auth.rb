require 'securerandom'

class Auth

  def init_module
    @auth_module = $modules[:Auth_dummy]
    puts @auth_module
    @auth_method = @auth_module.method(:valid_credentials?)
    @valid_tokens = []
  end

  def auth(username, passwd)
    if @auth_method.call(username, passwd)
      new_token = SecureRandom.uuid.gsub(/\-/,'')
      @valid_tokens << new_token
      return new_token
    else
      return false
    end
  end

  def valid_token?(token)
    return true if @valid_tokens.include?(token)
    return false
  end

  def auth_dummy(username, passwd)
    puts "Authentificating #{username}, #{passwd}"
    return true
  end

end
