@testset "sendmail.jl" begin
    (r1, r2, r3, r4) = ("hello.world@mail.com", "foo.bar@gmail.boo.com.tw", "goodmorning@coldmail.com", "pig.one@poop.com")

    @test [r1, r2, r3] == OkEMailSender.address_cleaner(r1 * " ;" * r2 * "; " * r3)
    @test [r1, r2, r3, r4] == OkEMailSender.address_cleaner([r1, r2, r3, " " * r4])
    @test [r4] == OkEMailSender.address_cleaner([" " * r4])
    for r in (r1, r2, r3, r4)
        @test r == only(OkEMailSender.address_cleaner([r * " "]))
        @test r == only(OkEMailSender.address_cleaner(r * ";"))
        @test r == only(OkEMailSender.address_cleaner(r))
        @test r == only(OkEMailSender.address_cleaner(r * " "))
    end
end
