require_relative '../lib/services/authentication'

describe Authentication do
    auth = Authentication.new(:internal, :admin, :user, :all)
    it 'Permission existence' do
        expect(auth.permission_exists? :internal).to be(true)
        expect(auth.permission_exists? :admin).to be(true)
        expect(auth.permission_exists? :user).to be(true)
        expect(auth.permission_exists? :all).to be(true)
        expect(auth.permission_exists? :other).to be(false)
    end

    it 'Permission allow' do
        expect(auth.permission_allow? :admin, :all).to be(false)
        expect(auth.permission_allow? :user, :admin).to be(true)
        expect(auth.permission_allow? :user, :other).to be(false)
        expect(auth.permission_allow? :other, :user).to be(false)
    end
end