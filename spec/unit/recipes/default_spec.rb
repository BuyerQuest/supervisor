require 'chefspec'
require 'chefspec/berkshelf'
require 'spec_helper'

describe 'supervisor::default' do
  let(:recipes) do
    %w(python)
  end

  platforms.each do |platform, details|
    versions = details['versions']
    versions.each do |version|
      # Run for each OS + OS Version
      context "On #{platform} #{version} with the default cookbook used for templates" do
        let(:chef_run) do
          runner = ChefSpec::SoloRunner.new(platform: platform, version: version)
          runner.converge(described_recipe)
        end

        before do
          # Mock the calls to include the other recipes so that they are not actually run, but we can check that they are included
          recipes.each do |recipe|
            allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe)
          end
        end

        it 'should call any other required recipes' do
          recipes.each do |recipe|
            expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe)
          end
          chef_run
        end

        if platform == 'smartos'
          it 'should install py27-expat on smartos only' do
            expect(chef_run).to install_package('py27-expat')
          end
        end

        it 'should install the supervisor package via PIP and create the supervisor directory' do
          expect(chef_run).to upgrade_python_pip('supervisor')
          expect(chef_run).to create_directory(chef_run.node['supervisor']['dir'])
        end

        it 'should create the configuration file template' do
          expect(chef_run).to create_template(chef_run.node['supervisor']['conffile']).with(:cookbook => nil)
        end

        it 'should create the supervisor log directory' do
          expect(chef_run).to create_directory(chef_run.node['supervisor']['log_dir'])
        end

        if platform == 'debian' or platform == 'ubuntu'
          it 'should create the default settings file' do
            expect(chef_run).to create_template('/etc/default/supervisor')
          end
        end

        # TODO: Add check for call to 'value_for_platform_family'

        it 'should configure, enable, and start the supervisor service using the default cookbook' do
          case platform
          when 'amazon', 'centos', 'debian', 'fedora', 'redhat', 'ubuntu', 'raspbian'
            # TODO: Test setting alternate cookbook names
            expect(chef_run).to create_template('/etc/init.d/supervisor')
            expect(chef_run).to enable_service('supervisor')
            expect(chef_run).to start_service('supervisor')
          when 'smartos'
            expect(chef_run).to create_directory('/opt/local/share/smf/supervisord')
            expect(chef_run).to create_template('/opt/local/share/smf/supervisord/manifest.xml')

            resource = chef_run.template('/opt/local/share/smf/supervisord/manifest.xml')
            expect(resource).to notify('execute[svccfg-import-supervisord]').to(:run).immediately

            expect(chef_run).to enable_service('supervisord')
          end
        end
      end

      context "On #{platform} #{version} with a custom cookbook used for templates" do
        let(:chef_run) do
          runner = ChefSpec::SoloRunner.new(platform: platform, version: version)
          runner.node.normal['supervisor']['templates']['conffile_cookbook'] = 'conf_cookbook'
          runner.node.normal['supervisor']['templates']['defaults_cookbook'] = 'defaults_cookbook'
          runner.node.normal['supervisor']['templates']['initscript_cookbook'] = 'initscript_cookbook'
          runner.node.normal['supervisor']['templates']['manifest_cookbook'] = 'manifest_cookbook'
          runner.converge(described_recipe)
        end

        before do
          # Mock the calls to include the other recipes so that they are not actually run, but we can check that they are included
          recipes.each do |recipe|
            allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe)
          end
        end

        it 'should call any other required recipes' do
          recipes.each do |recipe|
            expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with(recipe)
          end
          chef_run
        end

        if platform == 'smartos'
          it 'should install py27-expat on smartos only' do
            expect(chef_run).to install_package('py27-expat')
          end
        end

        it 'should install the supervisor package via PIP and create the supervisor directory' do
          expect(chef_run).to upgrade_python_pip('supervisor')
          expect(chef_run).to create_directory(chef_run.node['supervisor']['dir'])
        end

        it 'should create the configuration file template' do
          expect(chef_run).to_not create_template(chef_run.node['supervisor']['conffile']).with(:cookbook => nil)
        end

        it 'should create the configuration file template using the custom cookbook' do
          expect(chef_run).to create_template(chef_run.node['supervisor']['conffile'])
                              .with(:cookbook => 'conf_cookbook')
        end

        it 'should create the supervisor log directory' do
          expect(chef_run).to create_directory(chef_run.node['supervisor']['log_dir'])
        end

        if platform == 'debian' or platform == 'ubuntu'
          it 'should create the default settings file using the custom cookbook' do
            expect(chef_run).to create_template('/etc/default/supervisor').with(:cookbook => 'defaults_cookbook')
          end
        end

        # TODO: Add check for call to 'value_for_platform_family'

        it 'should configure, enable, and start the supervisor service using the custom cookbook' do
          case platform
          when 'amazon', 'centos', 'debian', 'fedora', 'redhat', 'ubuntu', 'raspbian'
            # TODO: Test setting alternate cookbook names
            expect(chef_run).to create_template('/etc/init.d/supervisor').with(:cookbook => 'initscript_cookbook')
            expect(chef_run).to enable_service('supervisor')
            expect(chef_run).to start_service('supervisor')
          when 'smartos'
            expect(chef_run).to create_directory('/opt/local/share/smf/supervisord')
            expect(chef_run).to create_template('/opt/local/share/smf/supervisord/manifest.xml')
                                .with(:cookbook => 'manifest_cookbook')

            resource = chef_run.template('/opt/local/share/smf/supervisord/manifest.xml')
            expect(resource).to notify('execute[svccfg-import-supervisord]').to(:run).immediately

            expect(chef_run).to enable_service('supervisord')
          end
        end
      end
    end
  end
end
