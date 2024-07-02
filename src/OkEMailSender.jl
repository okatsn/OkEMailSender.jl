module OkEMailSender
include("secrets.jl")


using SMTPClient, HypertextLiteral, Markdown

include("config.jl")

include("sendmail.jl")

export HTMLMail, PureTextMail, MarkdownMail
export send
end
