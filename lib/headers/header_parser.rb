module HeaderParser
    def list_kv_val(field, key, list_sep, kv_assign, strip=true)
        get(field)&.split(list_sep)&.each do |pair|
            v = strip ? pair.strip : pair
            i = v.index(kv_assign)
            field = i.nil? ? v : v[0..i-1]
            return i.nil? ? '' : v[i+1..-1] if field == key
        end
    end
end