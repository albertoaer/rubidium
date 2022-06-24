module Policy
    module Restart
        def restart?
            true
        end
    end
    module Abort
        def restart?
            false
        end
    end
end