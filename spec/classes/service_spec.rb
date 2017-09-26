require 'spec_helper'

describe 'uwsgi::service' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      let(:hiera_config) { 'hiera.yaml' }
      let(:pre_condition) do
        [
          'file {"/etc/uwsgi.ini": ensure => present}',
          'file {"/etc/uwsgi-emperor/emperor.ini": ensure => present}'
        ]
      end

      context 'without parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('uwsgi::service') }
        it { is_expected.to contain_service('uwsgi') }

        case facts[:osfamily]
        when 'Debian'
          case facts[:operatingsystemmajrelease]
          when '7'
            it { is_expected.to contain_file('/etc/init.d/uwsgi') }
          when '14.04'
            it { is_expected.to contain_file('/etc/init/uwsgi.conf') }
          end
        end
      end

      context 'with manage_file = true' do
        let(:params) { { 'manage_file' => true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('uwsgi::service') }
        it { is_expected.to contain_service('uwsgi') }

        case facts[:osfamily]
        when 'Debian'
          context 'on Debian' do
            case facts[:operatingsystemmajrelease]
            when '7'
              it { is_expected.to contain_file('/etc/init.d/uwsgi') }
            when '14.04'
              it { is_expected.to contain_file('/etc/init/uwsgi.conf') }
            else
              it { is_expected.to contain_file('/etc/systemd/system/uwsgi.service') }
            end
          end
        when 'RedHat'
          context 'on RedHat' do
            case facts[:operatingsystemmajrelease]
            when '6'
              it { is_expected.to contain_file('/etc/init.d/uwsgi') }
            else
              it { is_expected.to contain_file('/etc/systemd/system/uwsgi.service') }
            end
          end
        end
      end

      context 'with manage_file = true and kill_signal = SIGTERM' do
        let(:params) do
          {
            'manage_file' => true,
            'kill_signal' => 'SIGTERM',
            'template' => 'uwsgi/uwsgi_systemd.service.erb',
            'file' => '/etc/systemd/system/uwsgi.service'
          }
        end

        it do
          is_expected.to contain_file('/etc/systemd/system/uwsgi.service').
            with_content(%r{uwsgi --die-on-term}).
            with_content(%r{KillSignal=SIGTERM})
        end
      end
    end
  end
end
