require_relative "../config/environment.rb"
require 'active_support/inflector'
#needed to pluralize in self.table_name

class Song


  def self.table_name
    self.to_s.downcase.pluralize
    #takes the name of the class turns it into a string(to_s), downcases, and pluralizes it
    #creates our table name in a flexible way
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"
    #pragma will return to us an array of hashes describing the table itself using the results_as_hash method
    #each hash will contain information about one column
    table_info = DB[:conn].execute(sql)
    column_names = []
    
    table_info.each do |row|
      column_names << row["name"]
      #iterate over the resulting array of hashes to collect just the name of each column
    end
    column_names.compact
    #.compact is used to get rid of any nil values
    #the return value will be ["id", "name", "album"]
    #we will use this method to create our attr_accessors
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
    #iterate over the column names stored in the the column_names method and set an attr_accessor for each one
    #converts the column name string into a symbol 
  end

  def initialize(options={}) #defaults to an empty hash
    options.each do |property, value|
      self.send("#{property}=", value)
      #iterate over the options hash
      #use the send method to interpolate the name of each key as a method that we set equal to the key's value
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    #self refers to the instance of the class not the class itself so we need to use a class method inside an instance method
    #need to use instance methods of table_name_for_insert, values_for_insert, and col_names_for_insert which turn the returns into class 
    #string interpolation can cause SQL injection vulnerabilities
  end

  def table_name_for_insert
    self.class.table_name
    #turning table_name into a class method to use in the save method
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
      #iterate over the column names stored in column_names
      #send each individual column name to invoke the method of that name and capture the return value
      #push the return value of send into the values arrray unless the value is nil like it would be for id before save
      #putting the return value of send(col_name) into a single quotes string 
    end
    values.join(", ")
    #the above code will return a values array like this: ["'the name of the song'", "'the album of the song'"]
    #use join to return a comma separated string
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    #when you INSERT a row into a database for the first time, you don't INSERT the id as it is default to nil
    #you don't want to include the id column or insert a value for the id
    #you remove(delete_if) the column if it is id from the array returned from the method column names
    #turn the array into a comma separated list contained in a string(join(", "))
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



