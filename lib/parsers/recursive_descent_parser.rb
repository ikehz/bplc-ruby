module Parsers
  # a simple Parser
  class RecursiveDescentParser
    TYPE_SPECIFIERS = [:int, :void, :string].freeze

    def initialize(source)
      @source = source
      next_token
    end

    def parse
      if @parse
        return @parse
      else
        return @parse = program
      end
    end

    private

    #################
    # parse methods #
    #################

    def program
      p = Program.new(declarations)
      eat(:eof)
      return p
    end

    def declarations
      d = [declaration]
      while is_type_specifier?(current_token)
        d << declaration
      end
      return d
    end

    def declaration
      t = type_specifier
      if current_token.type == :asterisk
        eat(:asterisk)
        d = PointerDeclaration.new(t, id)
        eat(:semicolon)
      else
        i = id
        if current_token.type == :l_bracket
          eat(:l_bracket)
          d = ArrayDeclaration.new(t, i, num)
          eat(:r_bracket)
          eat(:semicolon)
        elsif current_token.type == :l_paren
          eat(:l_paren)
          p = params
          eat(:r_paren)
          d = FunctionDeclaration.new(t, i, p, compound_statement)
        else
          d = SimpleDeclaration.new(t, i)
          eat(:semicolon)
        end
      end
      return d
    end

    def params
      if current_token.type == :void
        eat(:void)
        return []
      else
        p = [param]
        while current_token.type == :comma
          eat(:comma)
          p << param
        end
        return p
      end
    end

    def param
      t = type_specifier
      if current_token.type == :asterisk
        eat(:asterisk)
        p = PointerParam.new(t, id)
      else
        i = id
        if current_token.type == :l_bracket
          eat(:l_bracket)
          eat(:r_bracket)
          p = ArrayParam.new(t, i)
        else
          p = SimpleParam.new(t, i)
        end
      end
      return p
    end

    def type_specifier
      if is_type_specifier?(current_token)
        return TypeSpecifier.new(eat_token)
      else
        raise SyntaxError, "expected type_specifier, got #{current_token.type.to_s}"
      end
    end

    def compound_statement
      eat(:l_brace)
      c = CompoundStatement.new(local_declarations, statements)
      eat(:r_brace)
      return c
    end

    def local_declarations
      d = []
      while is_type_specifier?(current_token)
        d << local_declaration
      end
      return d
    end

    def local_declaration
      t = type_specifier
      if current_token.type == :asterisk
        eat(:asterisk)
        d = PointerDeclaration.new(t, id)
        eat(:semicolon)
      else
        i = id
        if current_token.type == :l_bracket
          eat(:l_bracket)
          d = ArrayDeclaration.new(t, i, num)
          eat(:r_bracket)
          eat(:semicolon)
        else
          d = SimpleDeclaration.new(t, i)
          eat(:semicolon)
        end
      end
      return d
    end

    def statements
      s = []
      # XXX let's check for things, not for absence of things
      while !([:r_brace, :eof].include? current_token.type)
        s << statement
      end
      return s
    end

    # TODO unfinished
    def statement
      return expression_statement
    end

    def expression_statement
      if current_token.type == :semicolon
        s = ExpressionStatement.new(nil)
      else
        s = ExpressionStatement.new(expression)
      end
      eat(:semicolon)
      return s
    end

    # TODO unfinished
    def expression
      return SimpleExpression.new(e)
    end

    # TODO unfinished
    def e
      return E.new(id)
    end

    def id
      Id.new(eat(:id))
    end

    def num
      Num.new(eat(:num))
    end

    ###################
    # support methods #
    ###################

    def eat(type)
      if current_token.type == type
        eat_token
      else
        raise SyntaxError, "expected #{type.to_s}, got #{current_token.type.to_s}"
      end
    end

    def is_type_specifier?(token)
      TYPE_SPECIFIERS.include? token.type
    end

    def eat_token
      t = current_token
      next_token
      return t
    end

    def current_token
      @source.current_token
    end

    def next_token
      @source.next_token
    end
  end
end
