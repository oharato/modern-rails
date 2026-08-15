class AddKindToSolidQueueProcesses < ActiveRecord::Migration[8.0]
  def change
    add_column :solid_queue_processes, :kind, :string, null: false, default: "Worker"
  end
end
