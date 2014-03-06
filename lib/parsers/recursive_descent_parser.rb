module Parsers
  # a simple Parser that takes in a Scanner and builds a tree out of the successive tokens
  class RecursiveDescentParser
    def initialize(source)
      configure_source(source)
    end

    def parse
      if @parse
        return @parse
      else
        next_token
        parse_declaration_list
      end
    end

    private

    TYPE_SPECIFIERS = [:int, :void, :string]

    def parse_declaration_list
      p = Ast::DeclarationList.new(nil, parse_variable_declaration)
      while TYPE_SPECIFIERS.include? current_token.type
        p = Ast::DeclarationList.new(p, parse_variable_declaration)
      end
      return p
    end

    def parse_variable_declaration
      Ast::VariableDeclaration.new(parse_type_specifier, parse_id, parse_semicolon)
    end

    def parse_type_specifier
      Ast::TypeSpecifier.new(process_token)
    end

    def parse_id
      Ast::Id.new(process_token)
    end

    def parse_semicolon
      Ast::Semicolon.new(process_token)
    end

    ###################
    # support methods #
    ###################

    # source must either
    #   be a Scanner
    #   respond to #next_token and #current_token
    def configure_source(source)
      @source = source
    end

    def process_token
      r = current_token
      next_token
      return r
    end

    def next_token
      @source.next_token
    end

    def current_token
      @source.current_token
    end
  end
end
