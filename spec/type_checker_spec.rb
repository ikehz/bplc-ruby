require 'spec_helper'

describe TypeChecker do
  describe "#initialize" do
    it "can be constructed from an Ast" do
      expect(TypeChecker.new(resolve("int x; void main(void) { x; }"))).to be_a TypeChecker
    end
  end

  describe "#type_check" do

    # TODO?
    ###########
    # Program #
    ###########

    # TODO?
    ################
    # Declarations #
    ################

    # TODO?
    ##########
    # Params #
    ##########

    # TODO
    #########
    # Stmts #
    #########

    # no need to type-check the nodes below:
    # - CompoundStmt
    # - ExpStmt
    # - Return
    # - WritelnStmt

    describe "ConditionalStmt" do
      it "does not raise an error for an int condition" do
        expect{type_check('int x; void main(void) { if(x) ; }')}.not_to raise_error
        expect{type_check('int x; void main(void) { while(x) ; }')}.not_to raise_error
        expect{type_check('int x; void main(void) { if(x == 2) ; }')}.not_to raise_error
        expect{type_check('int x; void main(void) { while(x == 2) ; }')}.not_to raise_error
      end

      it "raises a SyntaxError for a non-int condition" do
        ['&x', '"a"', 'y', 'z', 'w'].each do |condition|
          expect{type_check("int x; string y; int *z; int w[2]; void main(void) { if(#{condition}) ; }")}.to raise_error(SyntaxError, "condition must be int")
          expect{type_check("int x; string y; int *z; int w[2]; void main(void) { while(#{condition}) ; }")}.to raise_error(SyntaxError, "condition must be int")
        end
      end
    end

    describe "Write"

    ########
    # Exps #
    ########

    describe "AssignmentExp" do
      it "are type-checked as int" do
        a = type_check('int x; int *y; int z[2]; void main(void) { x = 5; x = *y = z[0] = 10; x = *y; *y = z[1]; z[0] = x; }')

        body = a.declarations[3].body
        body.stmts.each do |s|
          expect(s.exp.type).to eq(:int)
        end
      end

      it "are type-checked as string" do
        a = type_check('string x; string *y; string z[2]; void main(void) { x = "a"; x = *y = z[0] = "b"; x = *y; *y = z[1]; z[0] = x; }')

        body = a.declarations[3].body
        body.stmts.each do |s|
          expect(s.exp.type).to eq(:string)
        end
      end

      it "are type-checked as pointer_int" do
        a = type_check('int x; int *y; int z[2]; int *w; void main(void) { y = &x; y = &z[0]; y = w = &z[1]; }')

        body = a.declarations[4].body
        body.stmts.each do |s|
          expect(s.exp.type).to eq(:pointer_int)
        end
      end

      it "are type-checked as pointer_string" do
        a = type_check('string x; string *y; string z[2]; string *w; void main(void) { y = &x; y = &z[0]; y = w = &z[1]; }')

        body = a.declarations[4].body
        body.stmts.each do |s|
          expect(s.exp.type).to eq(:pointer_string)
        end
      end

      it "raises a SyntaxError for array_int and array_string lhss" do
        expect{type_check('int x[1]; int y[5]; void main(void) { x = y; }')}.to raise_error(SyntaxError, "invalid assignment: cannot assign to array_int")
        expect{type_check('string x[1]; string y[5]; void main(void) { x = y; }')}.to raise_error(SyntaxError, "invalid assignment: cannot assign to array_string")
      end

      it "raises a SyntaxError if operands do not match" do
        expect{type_check('string x; void main(void) { x = 5; }')}.to raise_error(SyntaxError, "invalid assignment: cannot assign int to string")
        expect{type_check('int x; int *y; void main(void) { x = y; }')}.to raise_error(SyntaxError, "invalid assignment: cannot assign pointer_int to int")
      end
    end

    describe "RelExp" do
      it "are type-checked as int" do
        a = type_check('int x; int *y; void main(void) { x > 5; 5 == *y; -x != *y; x > -x % *y; }')

        body = a.declarations[2].body
        body.stmts.each do |s|
          expect(s.exp.type).to eq(:int)
        end
      end

      it "raises a SyntaxError if bad operands are used" do
        expect{type_check('string x; void main(void) { x < 5; }')}.to raise_error(SyntaxError, "invalid lhs: cannot lt string")
        expect{type_check('int x; void main(void) { 5 == &x; }')}.to raise_error(SyntaxError, "invalid rhs: cannot eq pointer_int")
        expect{type_check('int x[10]; void main(void) { 2 != x; }')}.to raise_error(SyntaxError, "invalid rhs: cannot neq array_int")
      end
    end

    describe "ArithmeticExp" do
      it "are type-checked as int" do
        a = type_check('int x; int *y; void main(void) { x + 5; 5 * *y; -x; x + -x % *y; }')

        body = a.declarations[2].body
        body.stmts.each do |s|
          expect(s.exp.type).to eq(:int)
        end
      end

      it "raises a SyntaxError if bad operands are used" do
        expect{type_check('string x; void main(void) { x + 5; }')}.to raise_error(SyntaxError, "invalid lhs: cannot plus string")
        expect{type_check('int x; void main(void) { 5 / &x; }')}.to raise_error(SyntaxError, "invalid rhs: cannot slash pointer_int")
        expect{type_check('int x[10]; void main(void) { -x; }')}.to raise_error(SyntaxError, "invalid exp: cannot minus array_int")
      end
    end

    ###########
    # VarExps #
    ###########

    # Since the type checker is organized to handle different VarExps by their
    # *declaration's* type, not *their* type, the specs are organized the same
    # way.

    describe "SimpleDeclaration" do
      it "assigns the correct type" do
        a = type_check('int x; string y; void main(void) { x; y; &x; &y; }')

        body = a.declarations[2].body
        expect(body.stmts[0].exp.type).to eq(:int)
        expect(body.stmts[1].exp.type).to eq(:string)
        expect(body.stmts[2].exp.type).to eq(:pointer_int)
        expect(body.stmts[3].exp.type).to eq(:pointer_string)
      end

      it "raises a SyntaxError if bad operators are used" do
        expect{type_check('int x; void main(void) { *x; }')}.to raise_error(SyntaxError, "cannot dereference int")
        expect{type_check('int x; void main(void) { x[1]; }')}.to raise_error(SyntaxError, "cannot index int")
        expect{type_check('int x; void main(void) { &x[1]; }')}.to raise_error(SyntaxError, "cannot index int")
      end
    end

    describe "PointerDeclaration" do
      it "assigns the correct type" do
        a = type_check('int *x; void main(void) { x; *x; }')

        body = a.declarations[1].body
        expect(body.stmts[0].exp.type).to eq(:pointer_int)
        expect(body.stmts[1].exp.type).to eq(:int)
      end

      it "raises a SyntaxError if bad operators are used" do
        expect{type_check('int *x; void main(void) { &x; }')}.to raise_error(SyntaxError, "cannot reference pointer_int")
        expect{type_check('int *x; void main(void) { x[1]; }')}.to raise_error(SyntaxError, "cannot index pointer_int")
        expect{type_check('int *x; void main(void) { &x[1]; }')}.to raise_error(SyntaxError, "cannot index pointer_int")
      end
    end

    describe "ArrayDeclaration" do
      it "assigns the correct type" do
        a = type_check('int x[2]; void main(void) { x; x[1]; &x[1]; }')

        body = a.declarations[1].body
        expect(body.stmts[0].exp.type).to eq(:array_int)
        expect(body.stmts[1].exp.type).to eq(:int)
        expect(body.stmts[2].exp.type).to eq(:pointer_int)
      end

      it "raises a SyntaxError if bad operators are used" do
        expect{type_check('int x[2]; void main(void) { *x; }')}.to raise_error(SyntaxError, "cannot dereference array_int")
        expect{type_check('int x[2]; void main(void) { &x; }')}.to raise_error(SyntaxError, "cannot reference array_int")
      end
    end

    describe "FunctionDeclaration" do
      it "assigns the correct type" do
        a = type_check('int f(void) { } string g(void) { } void h(void) { } void main(void) { f(); g(); h(); }')

        body = a.declarations[3].body
        expect(body.stmts[0].exp.type).to eq(:int)
        expect(body.stmts[1].exp.type).to eq(:string)
        expect(body.stmts[2].exp.type).to eq(:void)
      end
    end

    ###########
    # LitExps #
    ###########

    describe "LitExp" do
      it "assigns the correct type" do
        a = type_check('void main(void) { 2; "a"; read(); }')

        body = a.declarations[0].body
        expect(body.stmts[0].exp.type).to eq(:int)
        expect(body.stmts[1].exp.type).to eq(:string)
        expect(body.stmts[2].exp.type).to eq(:int)
      end
    end
  end
end
