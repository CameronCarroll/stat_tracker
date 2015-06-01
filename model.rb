require 'rubygems'
require 'bundler/setup'
require 'data_mapper'
require 'bcrypt'
require 'dm-postgres-adapter'

DataMapper.setup(:default, 'postgres://localhost/mydb')

class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial
  property :username, String, :length => 3..50
  property :password, BCryptHash
  has n, :records

  def authenticate(attempted_password)
    self.password == attempted_password
  end
end

class Record
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :type, String

  belongs_to :user
  has n, :data
end

class Datum
  include DataMapper::Resource

  property :id, Serial
  property :value, String
  property :date, DateTime

  belongs_to :record
end

DataMapper.finalize
DataMapper.auto_upgrade!
