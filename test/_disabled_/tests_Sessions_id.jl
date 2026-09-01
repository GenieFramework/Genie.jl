# @testitem "Sessions id test" setup=[GenieTestSetup] begin
#     using Genie

#     @test !isempty(Genie.secret_token())
#     @test Genie.Sessions.id() != Genie.Sessions.id()
# end;
