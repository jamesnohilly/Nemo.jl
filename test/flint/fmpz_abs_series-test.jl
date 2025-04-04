@testset "ZZAbsPowerSeriesRingElem.conformance_tests" begin
  R, x = power_series_ring(ZZ, 30, "x"; model=:capped_absolute)
  ConformanceTests.test_Ring_interface(R)
end

@testset "ZZAbsPowerSeriesRingElem.types" begin
  @test abs_series_type(ZZRingElem) == ZZAbsPowerSeriesRingElem
end

@testset "ZZAbsPowerSeriesRingElem.constructors" begin
  S1 = AbsPowerSeriesRing(ZZ, 30)
  S2 = AbsPowerSeriesRing(ZZ, 30)

  @test isa(S1, ZZAbsPowerSeriesRing)
  @test S1 !== S2

  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  @test elem_type(R) == ZZAbsPowerSeriesRingElem
  @test elem_type(ZZAbsPowerSeriesRing) == ZZAbsPowerSeriesRingElem
  @test parent_type(ZZAbsPowerSeriesRingElem) == ZZAbsPowerSeriesRing

  @test isa(R, ZZAbsPowerSeriesRing)

  a = x^3 + 2x + 1
  b = x^2 + 3x + O(x^4)

  @test isa(R(a), SeriesElem)

  @test isa(R([ZZ(1), ZZ(2), ZZ(3)], 3, 5), SeriesElem)

  @test isa(R([ZZ(1), ZZ(2), ZZ(3)], 3, 3), SeriesElem)

  @test isa(R(1), SeriesElem)

  @test isa(R(ZZ(2)), SeriesElem)

  @test isa(R(), SeriesElem)
end

@testset "ZZAbsPowerSeriesRingElem.printing" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  b = x^2 + 3x + O(x^4)

  @test sprint(show, "text/plain", b) == "3*x + x^2 + O(x^4)"
end

@testset "ZZAbsPowerSeriesRingElem.manipulation" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^4)

  @test is_gen(gen(R))

  @test iszero(zero(R))

  @test isone(one(R))

  @test is_unit(-1 + x + 2x^2)

  @test valuation(a) == 1

  @test valuation(b) == 4

  @test characteristic(R) == 0
end

@testset "ZZAbsPowerSeriesRingElem.similar" begin
  R, x = power_series_ring(ZZ, 10, "x"; model=:capped_absolute)

  for iters = 1:10
    f = rand(R, 0:10, -10:10)

    g = similar(f, ZZ, "y")
    h = similar(f, "y")
    k = similar(f)
    m = similar(f, ZZ, 5)
    n = similar(f, 5)

    @test isa(g, ZZAbsPowerSeriesRingElem)
    @test isa(h, ZZAbsPowerSeriesRingElem)
    @test isa(k, ZZAbsPowerSeriesRingElem)
    @test isa(m, ZZAbsPowerSeriesRingElem)
    @test isa(n, ZZAbsPowerSeriesRingElem)

    @test parent(g).S == :y
    @test parent(h).S == :y

    @test iszero(g)
    @test iszero(h)
    @test iszero(k)
    @test iszero(m)
    @test iszero(n)

    @test parent(g) !== parent(f)
    @test parent(h) !== parent(f)
    @test parent(k) === parent(f)
    @test parent(m) !== parent(f)
    @test parent(n) !== parent(f)

    p = similar(f, cached=false)
    q = similar(f, "z", cached=false)
    r = similar(f, "z", cached=false)
    s = similar(f)
    t = similar(f)

    @test parent(p) === parent(f)
    @test parent(q) !== parent(r)
    @test parent(s) === parent(t)
  end
end

@testset "ZZAbsPowerSeriesRingElem.abs_series" begin
  f = abs_series(ZZ, [1, 2, 3], 3, 5, "y")

  @test isa(f, ZZAbsPowerSeriesRingElem)
  @test base_ring(f) === ZZ
  @test coeff(f, 0) == 1
  @test coeff(f, 2) == 3
  @test parent(f).S == :y

  g = abs_series(ZZ, [1, 2, 3], 3, 5)

  @test isa(g, ZZAbsPowerSeriesRingElem)
  @test base_ring(g) === ZZ
  @test coeff(g, 0) == 1
  @test coeff(g, 2) == 3
  @test parent(g).S == :x

  h = abs_series(ZZ, [1, 2, 3], 2, 5)
  k = abs_series(ZZ, [1, 2, 3], 1, 6, cached=false)
  m = abs_series(ZZ, [1, 2, 3], 3, 9, cached=false)

  @test parent(h) === parent(g)
  @test parent(k) !== parent(m)

  p = abs_series(ZZ, ZZRingElem[], 0, 4)
  q = abs_series(ZZ, [], 0, 6)

  @test isa(p, ZZAbsPowerSeriesRingElem)
  @test isa(q, ZZAbsPowerSeriesRingElem)

  @test length(p) == 0
  @test length(q) == 0

  s = abs_series(ZZ, [1, 2, 3], 3, 5; max_precision=10)

  @test max_precision(parent(s)) == 10
end

@testset "ZZAbsPowerSeriesRingElem.unary_ops" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = 1 + 2x + x^2 + O(x^3)

  @test -a == -2x - x^3

  @test -b == -1 - 2x - x^2 + O(x^3)
end

@testset "ZZAbsPowerSeriesRingElem.binary_ops" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^4)
  c = 1 + x + 3x^2 + O(x^5)
  d = x^2 + 3x^3 - x^4

  @test a + b == x^3+2*x+O(x^4)

  @test a - c == x^3-3*x^2+x-1+O(x^5)

  @test b*c == O(x^4)

  @test a*c == 3*x^5+x^4+7*x^3+2*x^2+2*x+O(x^6)

  @test a*d == -x^7+3*x^6-x^5+6*x^4+2*x^3
end

@testset "ZZAbsPowerSeriesRingElem.adhoc_binary_ops" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^4)
  c = 1 + x + 3x^2 + O(x^5)
  d = x^2 + 3x^3 - x^4

  @test 2a == 4x + 2x^3

  @test Int128(2)*a == 4x + 2x^3

  @test ZZ(3)*b == O(x^4)

  @test c*2 == 2 + 2*x + 6*x^2 + O(x^5)

  @test d*ZZ(3) == 3x^2 + 9x^3 - 3x^4
end

@testset "ZZAbsPowerSeriesRingElem.comparison" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^3)
  c = 1 + x + 3x^2 + O(x^5)
  d = 3x^3 - x^4

  @test a == 2x + x^3

  @test b == d

  @test c != d
end

@testset "ZZAbsPowerSeriesRingElem.adhoc_comparison" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^0)
  c = 1 + O(x^5)
  d = R(3)

  @test d == 3

  @test c == ZZ(1)

  @test ZZ(0) != a

  @test 2 == b

  @test ZZ(1) == c
end

@testset "ZZAbsPowerSeriesRingElem.powering" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^4)
  c = 1 + x + 2x^2 + O(x^5)
  d = 2x + x^3 + O(x^4)

  @test a^12 == x^36+24*x^34+264*x^32+1760*x^30+7920*x^28+25344*x^26+59136*x^24+101376*x^22+126720*x^20+112640*x^18+67584*x^16+24576*x^14+4096*x^12 + O(x^30)

  @test b^12 == O(x^30)

  @test c^12 == 2079*x^4+484*x^3+90*x^2+12*x+1+O(x^5)

  @test d^12 == 4096*x^12+24576*x^14+O(x^15)

  @test_throws DomainError a^-1
end

@testset "ZZAbsPowerSeriesRingElem.shift" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^4)
  c = 1 + x + 2x^2 + O(x^5)
  d = 2x + x^3 + O(x^4)

  @test shift_left(a, 2) == 2*x^3+x^5

  @test_throws DomainError shift_left(a, -1)

  @test shift_left(b, 2) == O(x^6)

  @test shift_right(c, 1) == 1+2*x+O(x^4)

  @test_throws DomainError shift_left(c, -1)

  @test shift_right(d, 3) == 1+O(x^1)
end

@testset "ZZAbsPowerSeriesRingElem.truncation" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^4)
  c = 1 + x + 2x^2 + O(x^5)
  d = 2x + x^3 + O(x^4)
  e = x^3 + O(x^10)

  @test truncate(a, 3) == 2*x + O(x^3)

  @test_throws DomainError truncate(a, -1)

  @test truncate(b, 2) == O(x^2)

  @test truncate(c, 5) == 2*x^2+x+1+O(x^5)

  @test truncate(d, 5) == x^3+2*x+O(x^4)

  @test truncate(e, 2) == O(x^2)
end

@testset "ZZAbsPowerSeriesRingElem.exact_division" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = x + x^3
  b = O(x^4)
  c = 1 + x + 2x^2 + O(x^5)
  d = x + x^3 + O(x^6)

  @test divexact(a, d) == 1+O(x^5)

  @test divexact(d, a) == 1+O(x^5)

  @test divexact(b, c) == O(x^4)

  @test divexact(d, c) == -2*x^5+2*x^4-x^2+x+O(x^6)
end

@testset "ZZAbsPowerSeriesRingElem.adhoc_exact_division" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = x + x^3
  b = O(x^4)
  c = 1 + x + 2x^2 + O(x^5)
  d = x + x^3 + O(x^6)

  @test isequal(divexact(7a, 7), a)

  @test isequal(divexact(11b, ZZRingElem(11)), b)

  @test isequal(divexact(2c, ZZRingElem(2)), c)

  @test isequal(divexact(9d, 9), d)

  @test isequal(divexact(94872394861923874346987123694871329847a, 94872394861923874346987123694871329847), a)
end

@testset "ZZAbsPowerSeriesRingElem.inversion" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 1 + x + 2x^2 + O(x^5)
  b = R(-1)

  @test inv(a) == -x^4+3*x^3-x^2-x+1+O(x^5)

  @test inv(b) == -1
end

@testset "ZZAbsPowerSeriesRingElem.integral_derivative" begin
  R, x = power_series_ring(ZZ, 10, "x"; model=:capped_absolute)

  for iter = 1:100
    f = rand(R, 0:0, -10:10)

    @test integral(derivative(f)) == f - coeff(f, 0)
  end
end

@testset "ZZAbsPowerSeriesRingElem.square_root" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = rand(R, 0:10, -10:10)
  b = a^2

  @test isequal(sqrt(b)^2, b)
end

@testset "ZZAbsPowerSeriesRingElem.unsafe_operators" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  for iter = 1:300
    f = rand(R, 0:9, -10:10)
    g = rand(R, 0:9, -10:10)
    f0 = deepcopy(f)
    g0 = deepcopy(g)

    h = rand(R, 0:9, -10:10)

    k = f + g
    h = add!(h, f, g)
    @test isequal(h, k)
    @test isequal(f, f0)
    @test isequal(g, g0)

    f1 = deepcopy(f)
    f1 = add!(f1, f1, g)
    @test isequal(f1, k)
    @test isequal(g, g0)

    g1 = deepcopy(g)
    g1 = add!(g1, f, g1)
    @test isequal(g1, k)
    @test isequal(f, f0)

    f1 = deepcopy(f)
    f1 = add!(f1, g)
    @test isequal(h, k)
    @test isequal(g, g0)

    k = f*g
    h = mul!(h, f, g)
    @test isequal(h, k)
    @test isequal(f, f0)
    @test isequal(g, g0)

    f1 = deepcopy(f)
    f1 = mul!(f1, f1, g)
    @test isequal(f1, k)
    @test isequal(g, g0)

    g1 = deepcopy(g)
    g1 = mul!(g1, f, g1)
    @test isequal(g1, k)
    @test isequal(f, f0)

    h = zero!(h)
    @test isequal(h, R())
  end
end

@testset "ZZAbsPowerSeriesRingElem.set_precision" begin
  R, x = power_series_ring(ZZ, 30, "x", model=:capped_absolute)

  a = 2x + x^3
  b = O(x^4)
  c = 1 + x + 2x^2 + O(x^5)
  d = 2x + x^3 + O(x^4)
  e = x^3 + O(x^10)

  @test set_precision(a, 3) == 2*x + O(x^3)
  @test set_precision(b, 2) == O(x^2)
  @test set_precision(b, 10) == O(x^10)
  @test set_precision(c, 5) == 2*x^2+x+1+O(x^5)
  @test set_precision(c, 10) == 2*x^2+x+1+O(x^10)
  @test set_precision(d, 5) == x^3+2*x+O(x^5)
  @test set_precision(e, 2) == O(x^2)

  @test_throws DomainError set_precision(a, -1)
end
