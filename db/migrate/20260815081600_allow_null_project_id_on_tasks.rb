class AllowNullProjectIdOnTasks < ActiveRecord::Migration[8.0]
  def change
    change_column_null :tasks, :project_id, true
    change_column_default :tasks, :completed, from: nil, to: false
    change_column_null :tasks, :completed, false, false
  end
end
