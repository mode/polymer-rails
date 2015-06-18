require 'polymer-rails/component'

module Polymer
  module Rails
    class ComponentsProcessor < Sprockets::Processor

      def initialize(context, data)
        @context = context
        @component = Component.new(data)
      end

      def process
        inline_styles
        inline_javascripts
        require_imports
        @component.stringify
      end

    private

      def require_imports
        @component.imports.each do |import|
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
          puts '>>>>>>>>'
          puts search_file + ' + ' + path
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
