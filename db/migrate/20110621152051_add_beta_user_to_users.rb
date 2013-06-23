class AddBetaUserToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :beta_user, :boolean, :default => true
  end

  def self.down
    remove_column :users, :beta_user
  end
end
