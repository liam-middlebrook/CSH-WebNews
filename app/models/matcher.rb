class Matcher
  def apply(scope)
    scope.where(where_clause)
  end

  private

  def where_clause
    raise 'must be implemented in subclass'
  end

  def sanitize_conditions(*args)
    # FIXME: Non-protected alternative to this? Why is it protected anyway?
    ActiveRecord::Base.send(:sanitize_sql_array, args)
  end
end
