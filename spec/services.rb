require_relative '../lib/services/service'

describe 'Policies checkout' do
    class A < Service
        set_inspect true
    end
    class B < Service
        set_restart true
    end
    class C < Service
        set_inspect true
        set_restart true
    end
    class D < Service
    end
    it 'From A to D' do
        expect(A.do_inspect).to be(true)
        expect(A.do_restart).to be(false)
        expect(B.do_inspect).to be(false)
        expect(B.do_restart).to be(true)
        expect(C.do_inspect).to be(true)
        expect(C.do_restart).to be(true)
        expect(D.do_inspect).to be(false)
        expect(D.do_restart).to be(false)
    end
    it 'From D to A' do
        expect(D.do_inspect).to be(false)
        expect(D.do_restart).to be(false)
        expect(C.do_inspect).to be(true)
        expect(C.do_restart).to be(true)
        expect(B.do_inspect).to be(false)
        expect(B.do_restart).to be(true)
        expect(A.do_inspect).to be(true)
        expect(A.do_restart).to be(false)
    end
end