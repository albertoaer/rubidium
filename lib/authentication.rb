require_relative 'service'

class Authentication < Service
    def initialize(*permissions, &block)
        set_permissions(permissions)
        super(&block)
    end

    def set_permissions(permissions)
        raise 'Expecting [:internal, ..., :all] permission structure' if permissions.first != :internal or permissions.last != :all
        @permissions = permissions
    end

    def permission_exists?(auth)
        @permissions.include? auth
    end

    def permission_allow?(ref_auth, auth)
        (@permissions.index(ref_auth) or -1) >= (@permissions.index(auth) or @permissions.length)
    end
end