using Faker
using Model

function setup()
  Tester.reset_db()

  for i in 1:10 
    p = Package()
    p.name = Faker.word() * "_" * Faker.word() * "_" * Faker.word()
    p.url = Faker.uri() * "?" * string(hash(randn()))

    Model.save!(p)
  end
end

function teardown()
  Model.delete_all(Package)
end

facts("SQLWhere constructors") do
  context("Constructor with column name and value") do 
    @fact string(Model.SQLWhere(:id, 2)) --> """AND ( "id" = ( 2 ) )"""
    @fact string(Model.SQLWhere("id", 2)) --> """AND ( "id" = ( 2 ) )"""
    @fact string(Model.SQLWhere(:id, "foo")) --> """AND ( "id" = ( 'foo' ) )"""
    @fact string(Model.SQLWhere("id", "foo")) --> """AND ( "id" = ( 'foo' ) )"""
    @fact string(Model.SQLWhere(SQLColumn(:id), SQLInput("foo"))) --> """AND ( "id" = ( 'foo' ) )"""
    @fact string(Model.SQLWhere(SQLColumn("id"), SQLInput(2.56))) --> """AND ( "id" = ( 2.56 ) )"""
    @fact string(Model.SQLWhere(:id, SQLInput("random()", raw = true))) --> """AND ( "id" = ( random() ) )"""
  end

  context("Constructor with 3 values") do 
    @fact string(Model.SQLWhere(SQLColumn("""foo"bar"""), SQLInput(101), SQLLogicOperator("OR"))) --> """OR ( "foo""bar" = ( 101 ) )"""
  end

  context("Constructor with 4 values") do 
    @fact string(Model.SQLWhere(SQLColumn("""foo"bar"""), SQLInput("%oo%"), SQLLogicOperator("OR"), "LIKE")) --> """OR ( "foo""bar" LIKE ( '%oo%' ) )"""
  end
end

facts("SQLInput constructors") do 
  @fact SQLInput(100) |> string --> 100
  @fact SQLInput(100.45) |> string --> 100.45
  @fact SQLInput("foo") |> string --> "'foo'"
  @fact SQLInput("foo", raw = true) |> string --> "foo"
  @fact SQLInput("foo'bar") |> string --> "'foo''bar'"
  @fact SQLInput("foo'bar", raw = true) |> string --> "foo'bar"
  @fact SQLInput(SQLInput(2)) |> string --> 2
  @fact SQLInput([1, "foo", "ba'r", 5.6]) --> [SQLInput(1), SQLInput("foo"), SQLInput("ba'r"), SQLInput(5.6)]
end

facts("SQLInput equality") do 
  @fact SQLInput(2) --> SQLInput(2)
  @fact SQLInput("foo") --> SQLInput("foo")
  @fact SQLInput("2.5") --> SQLInput(2.5) |> not
  @fact SQLInput(4) --> SQLInput(4, raw = true)
  @fact SQLInput("baz") --> SQLInput("baz", raw = true)
  @fact SQLInput("foo'") --> SQLInput("foo'")
end

facts("SQLColumn constructors") do 
  @fact SQLColumn("foo") |> string --> "\"foo\""
  @fact SQLColumn("fo\"o") |> string --> "\"fo\"\"o\""
  @fact SQLColumn(:foo) |> string --> "\"foo\""
  @fact SQLColumn(SQLColumn(:id)) --> SQLColumn(:id)
  @fact SQLColumn(:id) == SQLColumn(:id) --> true
  @fact SQLColumn("i\"d") |> string --> "\"i\"\"d\""
  @fact SQLColumn("i\"d", raw = true) |> string --> "i\"d"
end

facts("SQLLogicOperator constructors") do 
  @fact SQLLogicOperator() |> string --> "AND"
  @fact SQLLogicOperator("OR") |> string --> "OR"
  @fact SQLLogicOperator("FOO") |> string --> "AND"
end

facts("SQLOrder constructors") do 
  @fact SQLOrder(:id) |> string --> "(\"id\" ASC)"
  @fact SQLOrder(:id, :desc) |> string --> "(\"id\" DESC)"
  @fact SQLOrder(:id, :asc) |> string --> "(\"id\" ASC)"
  @fact SQLOrder("id", "asc") |> string --> "(\"id\" ASC)"
  @fact SQLOrder("id", "foo") |> string --> "(\"id\" ASC)"
end

facts("SQLLimit constructors") do 
  @fact SQLLimit() |> string --> "ALL"
  @fact SQLLimit(2) |> string --> "2"
  @fact SQLLimit("foo") |> string --> "ALL"
  @fact SQLLimit("all") |> string --> "ALL"
  @fact SQLLimit("ALL") |> string --> "ALL"
end

facts("Fetch Select part") do 
  @fact Model.to_select_part(Package, collect(SQLColumn([:name, :url]))) |> string --> "SELECT \"name\", \"url\""
  @fact Model.to_select_part(Package, SQLColumn([:name, :url])) |> string --> "SELECT \"name\", \"url\""
  @fact Model.to_select_part(Package) |> string --> "SELECT \"packages\".\"id\" AS \"packages_id\", \"packages\".\"name\" AS \"packages_name\", \"packages\".\"url\" AS \"packages_url\", \"repos\".\"id\" AS \"repos_id\", \"repos\".\"package_id\" AS \"repos_package_id\", \"repos\".\"fullname\" AS \"repos_fullname\", \"repos\".\"readme\" AS \"repos_readme\", \"repos\".\"participation\" AS \"repos_participation\""
  @fact Model.to_select_part(Package, "*") |> string --> "SELECT *"
  @fact Model.to_select_part(Package, "name") |> string --> "SELECT \"name\""
end

facts("Join part") do 
  context("Empty join should use default columns") do 
    @fact Model.to_join_part(Package) |> strip --> "LEFT JOIN \"repos\" ON \"repos\".\"package_id\" = \"packages\".\"id\""
  end
end

facts("SQLQuery constructors") do 
  q = SQLQuery()
end

facts("Model basics") do
  @psst setup()

  context("Model::all should find 10 packages in the DB") do
      all_packages = @psst Model.all(Package)
      @fact length(all_packages) --> 10
  end

  context("Model::find without args should find 10 packages in the DB") do
      all_packages = @psst Model.find(Package)
      @fact length(all_packages) --> 10
  end

  context("Model::find with limit 5 should find 5 packages in the DB") do
      all_packages = @psst Model.find(Package, SQLQuery(limit = SQLLimit(5)))
      @fact length(all_packages) --> 5
  end

  context("Model::find with limit 5 and order DESC by id should find 5 packages in the DB and sort correctly") do
      all_packages = @psst Model.find(Package, SQLQuery(limit = SQLLimit(5), order = [SQLOrder(:id, "DESC")]))
      @fact [10, 9, 8, 7, 6] --> map(x -> Base.get(x.id), all_packages)
  end

  context("Model::rand_one should return a not null nullable model") do 
    package = @psst Model.rand_one(Package)
    @fact typeof(package) --> Nullable{JinnieModel}
    @fact isnull(package) --> false
  end

  context("Model::find_one should return a not null nullable package with the same id") do 
    package = @psst Model.find_one(Package, 1)
    @fact Base.get(package).id |> Base.get --> 1
  end

  context("Complex finds") do 
    @pending Model.find() --> :?
  end

  context("Find rand") do 
    @pending Model.rand() --> :?
  end

  context("Find one") do 
    @pending Model.find_one() --> :?
  end

  @psst teardown()
end