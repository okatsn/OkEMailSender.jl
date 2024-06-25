module OkEMailSender
include("secrets.jl")


using SMTPClient, HypertextLiteral

include("config.jl")

include("sendmail.jl")

export HTMLMail, PureTextMail
export send
end
