@testset "fqPolyRepFieldElem.conformance_tests" begin
  ConformanceTests.test_Field_interface_recursive(Native.finite_field(7, 5, "z")[1])
end

@testset "fqPolyRepFieldElem.constructors" begin
  R, x = Native.finite_field(7, 5, "x")

  @test elem_type(R) == fqPolyRepFieldElem
  @test elem_type(fqPolyRepField) == fqPolyRepFieldElem
  @test parent_type(fqPolyRepFieldElem) == fqPolyRepField

  Sy, y = polynomial_ring(residue_ring(ZZ, 3)[1], "y")
  Syy, yy = Native.GF(3)["y"]

  T, z = Native.finite_field(y^2 + 1, "z")
  T2, z2 = Native.finite_field(yy^2 + 1, "z")

  # check that one can leave out the name for the generator, or specify it as a symbol
  @test Native.finite_field(7, 5)[1] isa fqPolyRepField
  @test Native.finite_field(7, 5, :x)[1] isa fqPolyRepField
  @test Native.finite_field(y^2 + 1)[1] isa fqPolyRepField
  @test Native.finite_field(y^2 + 1, :x)[1] isa fqPolyRepField

  @test isa(R, fqPolyRepField)
  @test isa(T, fqPolyRepField)
  @test isa(T2, fqPolyRepField)

  @test isa(3x^4 + 2x^3 + 4x^2 + x + 1, fqPolyRepFieldElem)
  @test isa(z^2 + z + 1, fqPolyRepFieldElem)
  @test isa(z2^2 + z2 + 1, fqPolyRepFieldElem)

  a = R()

  @test isa(a, fqPolyRepFieldElem)

  b = R(4)
  c = R(ZZRingElem(7))

  @test isa(b, fqPolyRepFieldElem)

  @test isa(c, fqPolyRepFieldElem)

  d = R(c)

  @test isa(d, fqPolyRepFieldElem)

  e = R(Native.GF(7)(1))
  @test isa(e, fqPolyRepFieldElem)
  @test isone(e)

  @test isa(R(QQ(1)), fqPolyRepFieldElem)

  S, = residue_ring(ZZ, 14)
  @test isa(R(S(8)), fqPolyRepFieldElem)
  @test is_one(R(S(8)))

  # check for primality
  T3, z3 = Native.finite_field(yy^2 + 1, "z", check=false)
  @test isa(T2, fqPolyRepField)
  Syyy, yyy = polynomial_ring(residue_ring(ZZ, 4)[1], "y")
  @test yyy isa zzModPolyRingElem
  @test_throws DomainError Native.finite_field(yyy^2+1, "z")
end

@testset "fqPolyRepFieldElem.rand" begin
  R, x = Native.finite_field(7, 5, "x")

  test_rand(R)
  test_rand(R, 1:9)
  test_rand(R, Int16(1):Int16(9))
  test_rand(R, big(1):big(9))
  test_rand(R, ZZRingElem(1):ZZRingElem(9))
  test_rand(R, [3,9,2])
  test_rand(R, Int16[3,9,2])
  test_rand(R, BigInt[3,9,2])
  test_rand(R, ZZRingElem[3,9,2])
end

@testset "fqPolyRepFieldElem.unsafe_coeffs" begin
  R, a = Native.finite_field(23, 2, "a")

  b = R()

  @test Nemo.setindex_raw!(b, UInt(0), 0) == 0
  @test Nemo.setindex_raw!(b, UInt(0), 1) == 0
  @test Nemo.setindex_raw!(b, UInt(2), 1) == 2a
  @test Nemo.setindex_raw!(b, UInt(3), 0) == 2a + 3

  b = 2a + 3

  @test Nemo.setindex_raw!(b, UInt(0), 1) == 3
  @test Nemo.setindex_raw!(b, UInt(4), 0) == 4
  @test Nemo.setindex_raw!(b, UInt(0), 0) == 0

  @test fqPolyRepFieldElem(R, UInt[0, 0]) == 0
  @test fqPolyRepFieldElem(R, UInt[2, 0]) == 2
  @test fqPolyRepFieldElem(R, UInt[2, 3]) == 3a + 2

  @test coeffs_raw(2a + 3) == UInt[3, 2]
  @test coeffs_raw(R(3)) == UInt[3, 0]
  @test coeffs_raw(R()) == UInt[0, 0]
end

@testset "fqPolyRepFieldElem.printing" begin
  R, x = Native.finite_field(7, 5, "x")

  a = 3x^4 + 2x^3 + 4x^2 + x + 1

  @test sprint(show, "text/plain", a) == "3*x^4 + 2*x^3 + 4*x^2 + x + 1"
end

@testset "fqPolyRepFieldElem.manipulation" begin
  R, x = Native.finite_field(7, 5, "x")

  @test iszero(zero(R))

  @test isone(one(R))

  @test is_gen(gen(R))

  @test characteristic(R) == 7

  @test order(R) == ZZ(7)^5

  @test degree(R) == 5

  @test is_unit(x + 1)

  @test deepcopy(x + 1) == x + 1

  @test coeff(2x + 1, 1) == 2

  @test_throws DomainError coeff(2x + 1, -1)

  @test isa(modulus(R), fpPolyRingElem)

  @test defining_polynomial(R) isa fpPolyRingElem
  kt, t = Native.GF(7)["t"]
  @test parent(defining_polynomial(kt, R)) === kt
end

@testset "fqPolyRepFieldElem.unary_ops" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  @test -a == 6*x^4+4*x^2+x+6
end

@testset "fqPolyRepFieldElem.binary_ops" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1
  b = 3x^4 + 2x^2 + x + 1

  @test a + b == 4*x^4+5*x^2+2

  @test a - b == 5*x^4+x^2+5*x

  @test a*b == 3*x^3+2

  F7 = Native.GF(7)
  @test F7(5) + a == x^4 + 3x^2 + 6x + 6
  @test a + F7(5) == x^4 + 3x^2 + 6x + 6
  @test F7(5) * a == 5*x^4+x^2+2*x+5
  @test a * F7(5) == 5*x^4+x^2+2*x+5
end

@testset "fqPolyRepFieldElem.adhoc_binary" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  @test 3a == 3*x^4+2*x^2+4*x+3

  @test a*3 == 3*x^4+2*x^2+4*x+3

  @test a*ZZRingElem(5) == 5*x^4+x^2+2*x+5

  @test ZZRingElem(5)*a == 5*x^4+x^2+2*x+5

  @test 12345678901234567890123*a == 3*x^4+2*x^2+4*x+3

  @test a*12345678901234567890123 == 3*x^4+2*x^2+4*x+3
end

@testset "fqPolyRepFieldElem.powering" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  @test a^3 == x^4+6*x^3+5*x^2+5*x+6

  @test a^ZZRingElem(-5) == x^4+4*x^3+6*x^2+6*x+2
end

@testset "fqPolyRepFieldElem.comparison" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1
  b = 3x^4 + 2x^2 + 2

  @test b != a
  @test R(3) == R(3)
  @test isequal(R(3), R(3))
end

@testset "fqPolyRepFieldElem.inversion" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  b = inv(a)

  @test b == x^4+5*x^3+4*x^2+5*x

  @test b == a^-1
end

@testset "fqPolyRepFieldElem.exact_division" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1
  b = 3x^4 + 2x^2 + 2

  @test divexact(a, b) == 3*x^4+2*x^3+2*x^2+5*x

  @test b//a == 4*x^2+6*x+5
end

@testset "fqPolyRepFieldElem.gcd" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1
  b = 3x^4 + 2x^2 + x + 1

  @test gcd(a, b) == 1

  @test gcd(R(0), R(0)) == 0
end

@testset "fqPolyRepFieldElem.special_functions" begin
  R, x = Native.finite_field(7, 5, "x")

  a = x^4 + 3x^2 + 6x + 1

  @test tr(a) == 1

  @test norm(a) == 4

  @test frobenius(a) == x^4+2*x^3+3*x^2+5*x+1

  @test frobenius(a, 3) == 3*x^4+3*x^3+3*x^2+x+4

  M = frobenius_matrix(R)
  @test M == matrix(base_ring(M), [1 0 0 0 0;
                                   0 0 3 6 0;
                                   3 2 6 0 2;
                                   3 3 4 5 2;
                                   5 6 2 1 2])


  @test pth_root(a) == 4*x^4+3*x^3+4*x^2+5*x+2

  @test is_square(a^2)

  @test sqrt(a^2)^2 == a^2

  @test is_square_with_sqrt(a^2)[1]

  @test is_square_with_sqrt(a^2)[2]^2 == a^2

  @test !is_square(x*a^2)

  @test_throws ErrorException sqrt(x*a^2)

  @test !is_square_with_sqrt(x*a^2)[1]
end

@testset "fqPolyRepFieldElem.iteration" begin
  for n = [2, 3, 5, 13, 31]
    R, _ = Native.finite_field(n, 1, "x")
    elts = ConformanceTests.test_iterate(R)
    @test elts == R.(0:n-1)
    R, _ = Native.finite_field(n, rand(2:9), "x")
    ConformanceTests.test_iterate(R)
  end
end

@testset "fqPolyRepFieldElem.lift" begin
  R, x = Native.finite_field(23, 2, "x")
  f = 8x + 9
  S, y = polynomial_ring(Native.GF(23), "y")
  @test lift(S, f) == 8y + 9
end

@testset "fqPolyRepFieldElem.minpoly" begin
  F, a = Native.finite_field(7, 5, "a")

  f = minpoly(a)
  @test is_zero(f(a))
  @test degree(f) == degree(F)
  @test is_monic(f)

  f = charpoly(a)
  @test is_zero(f(a))
  @test degree(f) == degree(F)
  @test is_monic(f)

  g = minpoly(F(3))
  @test is_zero(g(F(3)))
  @test degree(g) == 1
  @test is_monic(g)

  g = charpoly(F(3))
  @test is_zero(g(F(3)))
  @test degree(g) == degree(F)
  @test is_monic(g)
end

@testset "fqPolyRepFieldElem.representation_matrix" begin
  F, a = Native.finite_field(7, 5, "a")

  @test is_one(representation_matrix(one(F)))
  @test is_zero(representation_matrix(zero(F)))

  M = representation_matrix(a)
  @test nrows(M) == degree(F)
  @test ncols(M) == degree(F)

  f = minpoly(M)
  g = minpoly(parent(f), a)
  @test f == g
end
