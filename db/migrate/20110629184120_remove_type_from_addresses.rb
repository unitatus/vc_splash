class RemoveTypeFromAddresses < ActiveRecord::Migration
  def self.up
    remove_column :addresses, :type
  end

  def self.down
    add_column :addresses, :type, :string
  end
end
