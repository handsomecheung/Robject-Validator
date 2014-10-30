class HashWithSymbolAccess < Hash
  def [](key)
    if self.keys.include?(key)
      return super(key)
    elsif key.is_a?(Symbol) and self.keys.include?(key.to_s)
      return super(key.to_s)
    end
  end

  def []=(key, value)
    if self.keys.include?(key)
      super(key, value)
    elsif key.is_a?(Symbol) and self.keys.include?(key.to_s)
      super(key.to_s, value)
    end
  end
end

class Hash
  def with_symbol_access
    return HashWithSymbolAccess[self.entries]
  end
end
