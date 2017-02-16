# TODO: Add comment header
class PropertyDecorator < Draper::Decorator
  delegate_all

  # TODO: Add comment header
  def confirmed?(field, conf_field, conf_val)
    if field && conf_field
      conf_field.upcase == conf_val
    else
      false
    end
  end

  # TODO: Add comment header
  def add_addnl_info(field, conf_field, val, affirmed, unaffirmed)
    if !field || !conf_field
      field
    else
      field + " " + (confirmed?(field, conf_field, val) ? affirmed : unaffirmed)
    end
  end
  
  def architect_qualified
    add_addnl_info object.architect, object.architectconfirmed,
      "Y", "(confirmed)", "(unconfirmed)"
  end

  def builder_qualified
    add_addnl_info object.builder, object.builderconfirmed,
      "Y", "(confirmed)", "(unconfirmed)"
  end

  def yearbuilt_qualified
    add_addnl_info object.yearbuilt, object.yearbuiltflag,
      "A", "(actual)", "(estimated)"
  end 
  
end # class PropertyDecorator < Draper::Decorator