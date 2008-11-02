class TextFieldWithDisabledState < NSTextField
  def setEnabled(enabled)
    super_setEnabled(enabled)
    setTextColor(enabled == 1 ? NSColor.controlTextColor : NSColor.disabledControlTextColor)
  end
end