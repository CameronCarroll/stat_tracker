require 'rubygems'
require 'bundler/setup'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'bcrypt'

DataMapper.setup(:default, "sqlite://#{Dir.pwd}/db.sqlite")

class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial, :key => true
  property :username, String, :length => 3..50
  property :password, BCryptHash

  def authenticate(attempted_password)
    self.password == attempted_password
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!

if User.count == 0
  @user = User.create(username: "admin")
  @user.password = "admin"
  @user.save
end
