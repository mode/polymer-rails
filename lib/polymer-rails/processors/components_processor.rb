require 'polymer-rails/component'

module Polymer
  module Rails
    class ComponentsProcessor
      VERSION = '1'

      def self.instance
        @instance ||= new
      end

      def self.call(input)
        instance.call(input)
      end

      def self.cache_key
        instance.cache_key
      end

      attr_reader :cache_key

      def initialize(options = {})
        @cache_key = [self.class.name, VERSION, options].freeze
      end

      def call(input)
        context = input[:environment].context_class.new(input)
        puts '>>>>>'
        puts context.root_path
        unless /webapp\/app\/assets\/javascripts$/.match(context.root_path)
          @context = context
          @component = Component.new(input[:data])
          inline_styles
          inline_javascripts
          require_imports
          @component.stringify
        else
          nil
        end
      end
    private

      def require_imports
        @component.imports.each do |import|
          puts
          @context.require_asset absolute_asset_path(import.attributes['href'].value)
          import.remove
        end
      end

      def inline_javascripts
        @component.javascripts.each do |script|
          @component.replace_node(script, 'script', asset_content(script.attributes['src'].value))
        end
      end

      def inline_styles
        @component.stylesheets.each do |link|
          @component.replace_node(link, 'style', asset_content(link.attributes['href'].value))
        end
      end

      def asset_content(file)
        asset_path = absolute_asset_path(file)
        asset      = find_asset(asset_path)
        unless asset.blank?
          @context.depend_on_asset asset_path
          asset.to_s
        else
          nil
        end
      end

      def absolute_asset_path(file)
        search_file = file.sub(/^(\.\.\/)+/, '/').sub(/^\/*/, '')
        ::Rails.application.assets.paths.each do |path|
          file_list = Dir.glob( "#{File.absolute_path search_file, path }*")
          return file_list.first unless file_list.blank?
        end
        components = Dir.glob("#{File.absolute_path file, File.dirname(@context.pathname)}*")
        return components.blank? ? nil : components.first
      end

      def find_asset(asset_path)
        ::Rails.application.assets.find_asset(asset_path)
      end

    end
  end
end
