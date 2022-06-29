module AttributeParser
    def list_kv_val(att, key, list_sep, kv_assign, strip=true)
        get(att)&.split(list_sep)&.each do |pair|
            v = strip ? pair.strip : pair
            i = v.index(kv_assign)
            att = i.nil? ? v : v[0..i-1]
            return i.nil? ? '' : v[i+1..-1] if att == key
        end
    end
end