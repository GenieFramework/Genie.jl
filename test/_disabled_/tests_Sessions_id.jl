@safetestset "Sessions id test" begin
    using Genie

    @test !isempty(Genie.secret_token())
    @test Genie.Sessions.id() != Genie.Sessions.id()
end;
