require_relative '../lib/middleware/session_provider'
require_relative '../lib/request'
require_relative '../lib/prototyping'
require_relative '../lib/services/authentication'

describe SessionProvider do
    session = SessionProvider.new :id

    it 'No session' do
        req = Request.new <<-REQ
GET / HTTP/1.1\n
REQ
        session.before(req)
        expect(req.session).not_to be(nil)
        expect(req.session.id).to be(nil)
        expect{req.session.data}.to raise_error(StandardError)
        expect{req.session.auth}.to raise_error(StandardError)
    end

    it 'Invalid Session' do
        req = Request.new <<-REQ
GET / HTTP/1.1\r
Cookie: id=123\r
REQ
        session.before(req)
        expect(req.session).not_to be(nil)
        expect(req.session.id).to be(nil)
        expect{req.session.data}.to raise_error(StandardError)
        expect{req.session.auth}.to raise_error(StandardError)
    end

    x = session.storage.create[0]

    it 'Valid Session' do
        req = Request.new <<-REQ
GET / HTTP/1.1\r
Cookie: id=#{x}\r
REQ
        session.before(req)
        expect(req.session).not_to be(nil)
        expect(req.session.id).to eq(x)
        expect(req.session.data).to be(nil)
        expect(req.session.auth).to be(:all)
    end

    it 'Valid Session Closed' do
        req = Request.new <<-REQ
GET / HTTP/1.1\r
Cookie: id=#{x}\r
REQ
        session.before(req)
        req.session.close
        expect(req.session).not_to be(nil)
        expect(req.session.id).not_to eq(x)
        expect{req.session.data}.to raise_error(StandardError)
        expect{req.session.auth}.to raise_error(StandardError)
    end

    x = session.storage.create[0] #When close, the session in 'x' was dropped from storage

    it 'Changed Valid Session' do
        req = Request.new <<-REQ
GET / HTTP/1.1\r
Cookie: id=#{x}\r
REQ
        session.before(req)
        req.session.new
        expect(req.session).not_to be(nil)
        expect(req.session.id).not_to eq(x)
        expect(req.session.data).to be(nil)
        expect(req.session.auth).to be(:all)
    end

    services = service_provider do
        provide Authentication.new(:internal, :admin, :all), is_permission?: :permission_exists?, allow?: :permission_allow?
    end

    it 'Written Session' do
        req = Request.new <<-REQ, &services
GET / HTTP/1.1\r
REQ
        session.before(req)
        req.session.new
        req.session.data = {user:'Username'}
        req.session.auth = :admin
        expect(req.session.data).to eq({user:'Username'})
        expect(req.session.auth).to eq(:admin)
    end
end