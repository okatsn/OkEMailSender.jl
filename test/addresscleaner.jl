@testset "addresscleaner.jl" begin
    @test isa(OkEMailSender.address_cleaner(String[]), Vector)
    @test isa(OkEMailSender.address_cleaner(""), Vector)
    @test length(OkEMailSender.address_cleaner(String[])) == 0
    @test length(OkEMailSender.address_cleaner("")) == 0
end
